#include "parsers.h"

common_chat_params common_chat_params_init_gemma4(const common_chat_template &    tmpl,
                                                         const autoparser::generation_params & inputs) {
    common_chat_params data;

    data.prompt            = common_chat_template_direct_apply_impl(tmpl, inputs);
    data.generation_prompt = common_chat_template_generation_prompt_impl(tmpl, inputs);

    if (inputs.add_generation_prompt && string_ends_with(data.prompt, "<turn|>\n")) {
        // This may happen if the model generates content + tool_call, the
        // template does not add the model's next turn and confuses the model
        // from emitting its proper reasoning token sequence.
        data.generation_prompt = "<|turn>model\n";
        data.prompt += data.generation_prompt;
    }

    data.message_delimiters = {
        { COMMON_CHAT_ROLE_USER,      "<|turn>user"  },
        { COMMON_CHAT_ROLE_ASSISTANT, "<|turn>model" },
    };

    data.format            = COMMON_CHAT_FORMAT_PEG_GEMMA4;
    data.supports_thinking  = true;
    data.thinking_start_tag = "<|channel>thought";
    data.thinking_end_tags  = {"<channel|>"};

    data.preserved_tokens = {
        "<|channel>",
        "<channel|>",
        "<|tool_call>",
        "<tool_call|>",
        "<|turn>",
    };

    if (inputs.has_continuation()) {
        const auto & msg = inputs.continue_msg;

        data.generation_prompt = string_ends_with(data.prompt, "<turn|>\n") ? "<|turn>model\n" : "";
        data.generation_prompt += "<|channel>thought\n" + msg.reasoning_content;
        if (inputs.continue_final_message == COMMON_CHAT_CONTINUATION_CONTENT) {
            data.generation_prompt += "<channel|>" + msg.render_content();
        }

        data.prompt += data.generation_prompt;
    }

    auto has_tools           = inputs.tools.is_array() && !inputs.tools.empty();
    auto has_response_format = !inputs.json_schema.is_null() && inputs.json_schema.is_object();
    auto include_grammar     = has_response_format || (has_tools && inputs.tool_choice != COMMON_CHAT_TOOL_CHOICE_NONE);
    auto extract_reasoning   = inputs.reasoning_format != COMMON_REASONING_FORMAT_NONE;

    auto parser = build_chat_peg_parser([&](common_chat_peg_builder & p) {
        auto start = p.rule("start", p.optional(p.literal("<|turn>model\n")));

        if (extract_reasoning) {
            p.rule("thought", p.literal("<|channel>thought") + p.space() + p.reasoning(p.until("<channel|>")) + p.literal("<channel|>"));
        } else {
            p.rule("thought", p.content(p.literal("<|channel>thought") + p.space() + p.until("<channel|>") + p.literal("<channel|>")));
        }

        auto consume_empty_channels = p.gbnf(p.zero_or_more(p.literal("<|channel>") + p.negate(p.literal("thought"))), "");
        auto thought = (p.peek(p.literal("<|channel>")) + consume_empty_channels + p.ref("thought")) | p.negate(p.literal("<|channel>"));

        if (has_response_format) {
            auto response_format = p.literal("```json") <<
                p.content(p.schema(p.json(), "response-format-schema", inputs.json_schema)) <<
                p.literal("```");
            return start + p.optional(thought) + response_format;
        }

        if (has_tools && inputs.tool_choice != COMMON_CHAT_TOOL_CHOICE_NONE) {
            // Gemma4 tool calling syntax
            // Rules should match traversal logic in gemma4_to_json()
            p.rule("gemma4-string-content", p.until("<|\"|>"));
            p.rule("gemma4-string", p.literal("<|\"|>") + p.ref("gemma4-string-content") + p.literal("<|\"|>"));
            p.rule("gemma4-bool", p.json_bool());
            p.rule("gemma4-null", p.json_null());
            p.rule("gemma4-number", p.json_number());
            p.rule("gemma4-dict-key", p.rule("gemma4-dict-key-name", p.chars("[^:}]", 1, -1)) + p.literal(":"));
            p.rule("gemma4-dict-kv", p.ref("gemma4-dict-key") + p.space() + p.ref("gemma4-value"));
            p.rule("gemma4-dict", [&]() {
                auto ws = p.space();
                auto member = p.ref("gemma4-dict-kv");
                auto members = p.sequence({member, p.zero_or_more(p.sequence({p.literal(","), ws, member}))});
                return p.sequence({
                    p.literal("{"), ws,
                    p.choice({p.literal("}"), p.sequence({members, ws, p.literal("}")})})
                });
            });
            p.rule("gemma4-array", [&]() {
                auto ws = p.space();
                auto value = p.ref("gemma4-value");
                auto elements = p.sequence({value, p.zero_or_more(p.sequence({p.literal(","), ws, value}))});
                return p.sequence({
                    p.literal("["), ws,
                    p.choice({p.literal("]"), p.sequence({elements, ws, p.literal("]")})})
                });
            });
            p.rule("gemma4-value", [&]() {
                return p.choice({
                    p.ref("gemma4-string"), p.ref("gemma4-dict"), p.ref("gemma4-array"),
                    p.ref("gemma4-number"), p.ref("gemma4-bool"), p.ref("gemma4-null")
                });
            });

            auto tool_choice = p.choice();

            foreach_function(inputs.tools, [&](const json & tool) {
                const auto & function = tool.at("function");
                std::string  name     = function.at("name");
                // TODO @aldehir : need to extend json-schema-to-grammar to produce more than JSON rules
                // const auto & params   = function.at("parameters");

                tool_choice |= p.rule("tool-" + name, p.tool(p.sequence({
                    p.tool_open(p.tool_name(p.literal(name)) + p.peek(p.literal("{"))),
                    p.tool_args(p.ref("gemma4-dict")),
                })));
            });

            auto tool_call = p.trigger_rule("tool-call", p.repeat(
                "<|tool_call>call:" + tool_choice + "<tool_call|>",
                /* min = */ inputs.tool_choice == COMMON_CHAT_TOOL_CHOICE_REQUIRED ? 1 : 0,
                /* max = */ inputs.parallel_tool_calls ? -1 : 1
            ));

            if (inputs.tool_choice == COMMON_CHAT_TOOL_CHOICE_REQUIRED) {
                return start + thought + tool_call;
            }

            auto scan_to_toolcall = p.rule("scan-to-toolcall", p.until("<|tool_call>"));
            auto content = p.rule("content", p.content(p.until_one_of({"<|channel>", "<channel|>", "<|tool_call>"})));
            auto message = p.rule("message", thought + content);
            return start + p.zero_or_more(message) + scan_to_toolcall + tool_call;
        }

        // Gemma 4 may emit an extra <|channel>thought\n<channel|> at the end of the content. It may
        // also emit a single trailing <channel|> token. Consume all complete reasoning blocks and
        // then stop at the first unmatched <channel|> token.
        auto content = p.rule("content", p.content(p.until_one_of({"<|channel>", "<channel|>"})));
        auto message = p.rule("message", thought + content);
        return start + p.one_or_more(message);
    });

    data.parser = parser.save();

    if (include_grammar) {
        data.grammar_lazy = !(has_response_format || (has_tools && inputs.tool_choice == COMMON_CHAT_TOOL_CHOICE_REQUIRED));
        data.grammar      = build_grammar([&](const common_grammar_builder & builder) {
            parser.build_grammar(builder, data.grammar_lazy);
        });

        data.grammar_triggers = {
            { COMMON_GRAMMAR_TRIGGER_TYPE_WORD, "<|tool_call>" },
        };
    }

    return data;
}
