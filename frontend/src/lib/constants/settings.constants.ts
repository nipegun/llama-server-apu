import { CLI_FLAGS } from './cli-flags.constants';
import { DEFAULT_MCP_CONFIG } from './mcp.constants';
import { SETTINGS_KEYS } from './settings-keys.constants';
import { TITLE_GENERATION } from './title-generation.constants';
import { FILE_GLOB_SEARCH_PICKERS } from './working-directory.constants';
import { fText } from '$lib/i18n';
import {
	Code,
	Database,
	Funnel,
	ListRestart,
	Monitor,
	Moon,
	PencilRuler,
	SlidersVertical,
	Sun
} from '@lucide/svelte';
import { SyncableParameterType } from '$lib/enums';
import { SettingsFieldType } from '$lib/enums/settings.enums';
import { ColorMode } from '$lib/enums/ui.enums';
import type {
	SettingsConfigValue,
	SettingsEntry,
	SettingsFieldConfig,
	SettingsSection,
	SettingsSectionEntry
} from '$lib/types';

/** Settings sections — slug is the routing identity, title is the display label. */
export const SETTINGS_SECTIONS = {
	AGENTIC: { slug: 'agentic', title: fText('settings.agentic') },
	DEVELOPER: { slug: 'developer', title: fText('settings.developer') },
	DISPLAY: { slug: 'display', title: fText('settings.display') },
	GENERAL: { slug: 'general', title: fText('settings.general') },
	IMPORT_EXPORT: { slug: 'import-export', title: fText('settings.importExport') },
	SAMPLING_PENALTIES: { slug: 'sampling-penalties', title: fText('messagec2a6d6f845bf') },
	TOOLS: { slug: 'tools', title: fText('settings.tools') }
} as const;

export const SETTINGS_SECTION_SLUGS = {
	AGENTIC: SETTINGS_SECTIONS.AGENTIC.slug,
	DEVELOPER: SETTINGS_SECTIONS.DEVELOPER.slug,
	DISPLAY: SETTINGS_SECTIONS.DISPLAY.slug,
	GENERAL: SETTINGS_SECTIONS.GENERAL.slug,
	IMPORT_EXPORT: SETTINGS_SECTIONS.IMPORT_EXPORT.slug,
	SAMPLING_PENALTIES: SETTINGS_SECTIONS.SAMPLING_PENALTIES.slug,
	TOOLS: SETTINGS_SECTIONS.TOOLS.slug
} as const;

export const SETTINGS_SECTION_TITLES = {
	AGENTIC: SETTINGS_SECTIONS.AGENTIC.title,
	DEVELOPER: SETTINGS_SECTIONS.DEVELOPER.title,
	DISPLAY: SETTINGS_SECTIONS.DISPLAY.title,
	GENERAL: SETTINGS_SECTIONS.GENERAL.title,
	IMPORT_EXPORT: SETTINGS_SECTIONS.IMPORT_EXPORT.title,
	SAMPLING_PENALTIES: SETTINGS_SECTIONS.SAMPLING_PENALTIES.title,
	TOOLS: SETTINGS_SECTIONS.TOOLS.title
} as const;

export const SETTINGS_REGISTRY: SettingsSectionEntry[] = [
	// General
	{
		icon: SlidersVertical,
		settings: [
			{
				defaultValue: ColorMode.SYSTEM,
				help: fText('messaged8c2701b0dce'),
				key: SETTINGS_KEYS.THEME,
				label: fText('messageefb52e7172b7'),
				options: [
					{ icon: Monitor, label: fText('message6725e7bbcd28'), value: ColorMode.SYSTEM },
					{ icon: Sun, label: fText('messagedbcd5e7bb7a0'), value: ColorMode.LIGHT },
					{ icon: Moon, label: fText('message60acc53f13a5'), value: ColorMode.DARK }
				],
				type: SettingsFieldType.SELECT
			},
			{
				defaultValue: '',
				help: fText('message590ca5f81094', { p0: CLI_FLAGS.API_KEY }),
				isPrivate: true,
				key: SETTINGS_KEYS.API_KEY,
				label: fText('message23189d55f697'),
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: '',
				help: fText('messagefbd01c02e202'),
				key: SETTINGS_KEYS.SYSTEM_MESSAGE,
				label: fText('message8e5a3143184d'),
				type: SettingsFieldType.TEXTAREA
			},
			{
				defaultValue: true,
				help: fText('message8cae084b4d35'),
				key: SETTINGS_KEYS.SHOW_SYSTEM_MESSAGE,
				label: fText('messageb710ee80506f'),
				standaloneField: false,
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: 2500,
				help: fText('messaged50c4251977a'),
				key: SETTINGS_KEYS.PASTE_LONG_TEXT_TO_FILE_LEN,
				label: fText('message401b499e8e8f'),
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: true,
				help: fText('message819c91d143be'),
				key: SETTINGS_KEYS.SEND_ON_ENTER,
				label: fText('message7240e16f8c6b'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: true,
				help: fText('message569a6b44e53d'),
				key: SETTINGS_KEYS.AUTO_MIC_ON_EMPTY,
				label: fText('message8666460b20dc'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('messagec25279367499'),
				isExperimental: true,
				key: SETTINGS_KEYS.ENABLE_CONTINUE_GENERATION,
				label: fText('message086d634416fb'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: true,
				help: fText('message2798ae6854ed'),
				key: SETTINGS_KEYS.TITLE_GENERATION_USE_FIRST_LINE,
				label: fText('message5b5cd3e853ae'),
				radioOptions: [
					{
						key: SETTINGS_KEYS.TITLE_GENERATION_USE_FIRST_LINE,
						label: fText('messaged260b3167eca'),
						value: 'firstLine'
					},
					{
						isExperimental: true,
						key: SETTINGS_KEYS.TITLE_GENERATION_USE_LLM,
						label: fText('message979477c8d433'),
						value: 'llm'
					}
				],
				type: SettingsFieldType.RADIO
			},
			{
				defaultValue: TITLE_GENERATION.DEFAULT_PROMPT,
				dependsOn: SETTINGS_KEYS.TITLE_GENERATION_USE_LLM,
				help: fText('messaged737cb824eb4'),
				key: SETTINGS_KEYS.TITLE_GENERATION_PROMPT,
				label: fText('message20e4c1fbfbc0'),
				type: SettingsFieldType.TEXTAREA
			},
			{
				defaultValue: false,
				help: fText('message0e24ac7791c3'),
				key: SETTINGS_KEYS.TITLE_GENERATION_USE_LLM,
				label: fText('message979477c8d433'),
				standaloneField: false,
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('messagebac76e8ab9fb'),
				key: SETTINGS_KEYS.COPY_TEXT_ATTACHMENTS_AS_PLAIN_TEXT,
				label: fText('messageba488dcfbd3e'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('message96fe65afdb37'),
				key: SETTINGS_KEYS.PDF_AS_IMAGE,
				label: fText('message9ec72f537886'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: 0,
				help: fText('messagea9e27241ec14'),
				key: SETTINGS_KEYS.MAX_IMAGE_RESOLUTION,
				label: fText('message2954877fdbea'),
				type: SettingsFieldType.INPUT
			}
		],
		slug: SETTINGS_SECTION_SLUGS.GENERAL,
		title: SETTINGS_SECTION_TITLES.GENERAL
	},
	// Display
	{
		icon: Monitor,
		settings: [
			{
				defaultValue: true,
				help: fText('message1e886427b492'),
				key: SETTINGS_KEYS.SHOW_MESSAGE_STATS,
				label: fText('message58767901d07b'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				dependsOn: SETTINGS_KEYS.SHOW_MESSAGE_STATS,
				help: fText('messaged531a39769ee'),
				key: SETTINGS_KEYS.SHOW_AGENTIC_TURN_STATS,
				label: fText('message795b48b44734'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: true,
				help: fText('messagea51f7f782ae8'),
				key: SETTINGS_KEYS.SHOW_THOUGHT_IN_PROGRESS,
				label: fText('messagec699c01d5c4c'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('message0a711551837d'),
				key: SETTINGS_KEYS.ALWAYS_SHOW_TOOL_CALL_CONTENT,
				label: fText('message9ae2d6e1f7ed'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: true,
				help: fText('message9f72dcfe1de8'),
				key: SETTINGS_KEYS.RENDER_USER_CONTENT_AS_MARKDOWN,
				label: fText('message11910b83c707'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: true,
				help: fText('message3b2811cf8cbc'),
				key: SETTINGS_KEYS.RENDER_THINKING_AS_MARKDOWN,
				label: fText('message047a9804886c'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('message7f545155cd7c'),
				key: SETTINGS_KEYS.FULL_HEIGHT_CODE_BLOCKS,
				label: fText('messageee7633d878e8'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('message3253a89f0cd9'),
				key: SETTINGS_KEYS.DISABLE_AUTO_SCROLL,
				label: fText('message1d17af5ec5f4'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('message2d79bf0c56fd'),
				key: SETTINGS_KEYS.ALWAYS_SHOW_SIDEBAR_ON_DESKTOP,
				label: fText('message87776621d9c2'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: true,
				help: fText('messageaf8f1c9f28ca'),
				key: SETTINGS_KEYS.CONVERSATION_TABS,
				label: fText('messageb97856610c7e'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('message980c9fab0818'),
				key: SETTINGS_KEYS.SHOW_RAW_MODEL_NAMES,
				label: fText('message8dfac9650c4a'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: true,
				help: fText('message49aedab8ac92'),
				key: SETTINGS_KEYS.SHOW_MODEL_QUANTIZATION,
				label: fText('messageb1c372445053'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: true,
				help: fText('message0ed5075d0dba'),
				key: SETTINGS_KEYS.SHOW_MODEL_TAGS,
				label: fText('message68d073cd1d69'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('messagec3511f2d1a5f'),
				key: SETTINGS_KEYS.SHOW_MODEL_ORG_NAME_IN_TRIGGER,
				label: fText('message111ce3878078'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('message216237a41c51'),
				key: SETTINGS_KEYS.SHOW_BUILD_VERSION,
				label: fText('message4d8d312c1cf1'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('messagebd846f86005a'),
				key: SETTINGS_KEYS.SHOW_FULL_PATH_IN_MENTIONS,
				label: fText('messagec1ad5789407e'),
				type: SettingsFieldType.CHECKBOX
			}
		],
		slug: SETTINGS_SECTION_SLUGS.DISPLAY,
		title: SETTINGS_SECTION_TITLES.DISPLAY
	},
	// MCP Servers (non-UI config object)
	{
		icon: PencilRuler,
		settings: [
			{
				defaultValue: '[]',
				help: fText('message7b544c202be9'),
				key: SETTINGS_KEYS.MCP_SERVERS,
				label: fText('message22a7559f09bf'),
				standaloneField: false,
				type: SettingsFieldType.INPUT
			}
		],
		slug: SETTINGS_SECTION_SLUGS.TOOLS,
		title: SETTINGS_SECTION_TITLES.TOOLS
	},
	// Tools
	{
		icon: ListRestart,
		settings: [
			{
				defaultValue: 10,
				help: fText('messagef8db79fce786'),
				isPositiveInteger: true,
				key: SETTINGS_KEYS.AGENTIC_MAX_TURNS,
				label: fText('message7e334c6eec91'),
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: DEFAULT_MCP_CONFIG.requestTimeoutSeconds,
				help: fText('messageeb6b3380faf2'),
				isPositiveInteger: true,
				key: SETTINGS_KEYS.MCP_REQUEST_TIMEOUT_SECONDS,
				label: fText('messagece1c49ac8a96'),
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: FILE_GLOB_SEARCH_PICKERS.DEFAULT_SEARCH_DEPTH,
				help: fText('messagee75e8c21b6d9'),
				isPositiveInteger: true,
				key: SETTINGS_KEYS.MENTION_SEARCH_MAX_DEPTH,
				label: fText('message4183fb353c42'),
				max: FILE_GLOB_SEARCH_PICKERS.MAX_SEARCH_DEPTH,
				min: 1,
				placeholder: `${FILE_GLOB_SEARCH_PICKERS.DEFAULT_SEARCH_DEPTH}`,
				type: SettingsFieldType.INPUT
			}
		],
		slug: SETTINGS_SECTION_SLUGS.AGENTIC,
		title: SETTINGS_SECTION_TITLES.AGENTIC
	},
	// Import/Export
	{
		icon: Database,
		settings: [],
		slug: SETTINGS_SECTION_SLUGS.IMPORT_EXPORT,
		title: SETTINGS_SECTION_TITLES.IMPORT_EXPORT
	},
	// Sampling
	{
		icon: Funnel,
		settings: [
			{
				defaultValue: undefined,
				help: fText('message4a6ef954759e'),
				key: SETTINGS_KEYS.TEMPERATURE,
				label: fText('messageb958ce8b871a'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.TEMPERATURE
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('messageff2049bb8185'),
				key: SETTINGS_KEYS.DYNATEMP_RANGE,
				label: fText('message262220def130'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.DYNATEMP_RANGE
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('messageed4443b1e4aa'),
				key: SETTINGS_KEYS.DYNATEMP_EXPONENT,
				label: fText('messagee7499a75dbee'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.DYNATEMP_EXPONENT
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('message8dbff0f8b0d9'),
				key: SETTINGS_KEYS.TOP_K,
				label: fText('message74fc1150e902'),
				sync: { paramType: SyncableParameterType.NUMBER, serverKey: SETTINGS_KEYS.TOP_K },
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('messagec42b88da2f69'),
				key: SETTINGS_KEYS.TOP_P,
				label: fText('messagec7a8872a31da'),
				sync: { paramType: SyncableParameterType.NUMBER, serverKey: SETTINGS_KEYS.TOP_P },
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('messagebbd244420e7b'),
				key: SETTINGS_KEYS.MIN_P,
				label: fText('messageb0815a3244ed'),
				sync: { paramType: SyncableParameterType.NUMBER, serverKey: SETTINGS_KEYS.MIN_P },
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('messagec718b5a0c65c'),
				key: SETTINGS_KEYS.XTC_PROBABILITY,
				label: fText('messagef137399227a7'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.XTC_PROBABILITY
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('message48793e125258'),
				key: SETTINGS_KEYS.XTC_THRESHOLD,
				label: fText('messaged4ba9412017a'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.XTC_THRESHOLD
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('message2a4f56aa43d8'),
				key: SETTINGS_KEYS.TYP_P,
				label: fText('message866fba8d4873'),
				sync: { paramType: SyncableParameterType.NUMBER, serverKey: SETTINGS_KEYS.TYP_P },
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('message0afe6457ffaf'),
				key: SETTINGS_KEYS.MAX_TOKENS,
				label: fText('message409e75c09fcc'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.MAX_TOKENS
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: '',
				help: fText('message0527a017301b'),
				key: SETTINGS_KEYS.SAMPLERS,
				label: fText('message1c9adac18d8e'),
				sync: { paramType: SyncableParameterType.STRING, serverKey: SETTINGS_KEYS.SAMPLERS },
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: false,
				help: fText('messaged18beca92501'),
				key: SETTINGS_KEYS.BACKEND_SAMPLING,
				label: fText('message20d1867091ca'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: undefined,
				help: fText('messageea4a39630c59'),
				key: SETTINGS_KEYS.REPEAT_LAST_N,
				label: fText('messagec917bb45649a'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.REPEAT_LAST_N
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('messagedf8fffc1e7e8'),
				key: SETTINGS_KEYS.REPEAT_PENALTY,
				label: fText('messagebbbc898044f9'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.REPEAT_PENALTY
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('message1f5fec90f468'),
				key: SETTINGS_KEYS.PRESENCE_PENALTY,
				label: fText('message5891319b9abe'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.PRESENCE_PENALTY
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('messagecc7e2f1ca212'),
				key: SETTINGS_KEYS.FREQUENCY_PENALTY,
				label: fText('message7f9413709c95'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.FREQUENCY_PENALTY
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('messagee52fc11a5708'),
				key: SETTINGS_KEYS.DRY_MULTIPLIER,
				label: fText('messagea473fa39828e'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.DRY_MULTIPLIER
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('message29ed70517b86'),
				key: SETTINGS_KEYS.DRY_BASE,
				label: fText('messagef982fb90c90b'),
				sync: { paramType: SyncableParameterType.NUMBER, serverKey: SETTINGS_KEYS.DRY_BASE },
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('message06ba2e536c75'),
				key: SETTINGS_KEYS.DRY_ALLOWED_LENGTH,
				label: fText('message88e074dbde59'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.DRY_ALLOWED_LENGTH
				},
				type: SettingsFieldType.INPUT
			},
			{
				defaultValue: undefined,
				help: fText('messagee804042a5e31'),
				key: SETTINGS_KEYS.DRY_PENALTY_LAST_N,
				label: fText('messagec8ab732e8d70'),
				sync: {
					paramType: SyncableParameterType.NUMBER,
					serverKey: SETTINGS_KEYS.DRY_PENALTY_LAST_N
				},
				type: SettingsFieldType.INPUT
			}
		],
		slug: SETTINGS_SECTION_SLUGS.SAMPLING_PENALTIES,
		title: SETTINGS_SECTION_TITLES.SAMPLING_PENALTIES
	},
	// Developer
	{
		icon: Code,
		settings: [
			{
				defaultValue: false,
				help: fText('messageb59a8e16b7c0'),
				key: SETTINGS_KEYS.PRE_ENCODE_CONVERSATION,
				label: fText('message642329b42435'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('messageda5c0c85580d'),
				key: SETTINGS_KEYS.DISABLE_REASONING_PARSING,
				label: fText('message70edf5da9d33'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('message6c6741612135'),
				key: SETTINGS_KEYS.EXCLUDE_REASONING_FROM_CONTEXT,
				label: fText('message1f3579b2968e'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('message2da37fca08fe'),
				key: SETTINGS_KEYS.SHOW_RAW_OUTPUT_SWITCH,
				label: fText('message922618c6a92e'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				help: fText('message328ff7861fd0'),
				key: SETTINGS_KEYS.JS_SANDBOX_ENABLED,
				label: fText('message085046e2a92a'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: false,
				dependsOn: SETTINGS_KEYS.JS_SANDBOX_ENABLED,
				help: fText('message03344003f473'),
				key: SETTINGS_KEYS.SYMBOLIC_MATH_ENABLED,
				label: fText('message072ccd309854'),
				type: SettingsFieldType.CHECKBOX
			},
			{
				defaultValue: '',
				help: fText('messagec0eecd6c7ea5'),
				key: SETTINGS_KEYS.CUSTOM_JSON,
				label: fText('message4b225723787e'),
				type: SettingsFieldType.TEXTAREA
			},
			{
				defaultValue: '',
				help: fText('messageeddb4b393605'),
				key: SETTINGS_KEYS.CUSTOM_CSS,
				label: fText('message9d3b9a0e78ea'),
				type: SettingsFieldType.TEXTAREA
			}
		],
		slug: SETTINGS_SECTION_SLUGS.DEVELOPER,
		title: SETTINGS_SECTION_TITLES.DEVELOPER
	}
];

function getAllSettings(): SettingsEntry[] {
	const result: SettingsEntry[] = [];

	for (const section of SETTINGS_REGISTRY) {
		result.push(...section.settings);
	}

	return result;
}

/** Flat config object stored in localStorage. */
export const SETTING_CONFIG_DEFAULT: Record<string, SettingsConfigValue> = Object.fromEntries(
	getAllSettings().map((s) => [s.key, s.defaultValue])
) as Record<string, SettingsConfigValue>;

/** Help text for every setting (including non-UI). */
export const SETTING_CONFIG_INFO: Record<string, string> = Object.fromEntries(
	getAllSettings().map((s) => [s.key, s.help])
) as Record<string, string>;

/** Sidebar sections + field configs (as consumed by UI). */
function toSettingsSection(section: SettingsSectionEntry): SettingsSection {
	return {
		fields: section.settings
			.filter((s) => s.standaloneField !== false)
			.map((s) => ({
				dependsOn: s.dependsOn,
				help: s.help,
				isExperimental: s.isExperimental,
				isPositiveInteger: s.isPositiveInteger,
				isPrivate: s.isPrivate,
				key: s.key,
				label: s.label,
				max: s.max,
				min: s.min,
				options: s.options as SettingsFieldConfig['options'],
				placeholder: s.placeholder,
				radioOptions: s.radioOptions,
				type: s.type
			})),
		icon: section.icon,
		slug: section.slug,
		title: section.title
	};
}

/** Sidebar sections in custom display order (the registry array order). */
export const SETTINGS_CHAT_SECTIONS: SettingsSection[] = SETTINGS_REGISTRY.map(toSettingsSection);

/** INPUT-type settings whose value is a number. */
export const NUMERIC_FIELDS = getAllSettings()
	.filter((s) => s.type === SettingsFieldType.INPUT && typeof s.defaultValue !== 'string')
	.map((s) => s.key) as readonly string[];

/** Numeric fields clamped to >= 1 and rounded. */
export const POSITIVE_INTEGER_FIELDS = getAllSettings()
	.filter((s) => s.isPositiveInteger)
	.map((s) => s.key) as readonly string[];
