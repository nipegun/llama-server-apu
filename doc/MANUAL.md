# User manual

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [First start](#first-start)
- [Conversations and settings](#conversations-and-settings)
- [Files and tools](#files-and-tools)
- [API](#api)
- [APU tuning](#apu-tuning)
- [Memory and Vulkan](#memory-and-vulkan)
- [Operations](#operations)
- [Build without deploying services](#build-without-deploying-services)
- [Self-contained local build](#self-contained-local-build)
- [Upstream update and measurements](#upstream-update-and-measurements)
- [Compatibility and limitations](#compatibility-and-limitations)

## Requirements

Use the remote installer below or a local source copy on the production server, with an x86-64 processor, a Vulkan-capable GPU with its driver and a GGUF model (format version 3) produced by a current llama.cpp converter. Compilation targets the processor on which it runs. Debian 13 or a current Alpine installation needs CMake, a C/C++ toolchain, Vulkan development files, OpenSSL, Node.js (20.19+ or 22.12+) and npm; the installers obtain distribution packages.

The project keeps no backward compatibility: models or multimodal projectors converted with older llama.cpp versions, browser data saved by earlier versions of the interface, deprecated options and removed API routes are not supported. Reconvert or download a recent version of an old model; the [compatibility section](#compatibility-and-limitations) lists what changed.

The source workstation and production server are different machines. Run installation on production as **root**. The project does not use sudo or Git.

## Installation

Run this from any directory as root on the production server. The initial download requires curl and trusted CA certificates:

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/deploy/install-update-reinstall-debian.sh | bash
```

The Debian entry point downloads a complete snapshot of `main` without Git into `/opt/llama-server-apu-source`. No local checkout is required. On the first installation, if `--model` is omitted, it asks for the local GGUF path through `/dev/tty`. Without a terminal, supply the arguments explicitly:

```bash
curl -fsSL https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/deploy/install-update-reinstall-debian.sh | bash -s -- \
  --model /path/to/model.gguf --domain ai.example.com
```

The prompt never reads from the downloaded script on standard input. A missing model without a terminal stops the installer with instructions. The default domain is localhost when no saved setting or explicit domain is available. The original model file is preserved when the installer copies it.

Repeat the first command to update or reinstall. It refreshes the managed sources while preserving `_/temp/` (build files and npm cache), reuses the installed model, API key and certificates, and restores the saved domain, prefix and UI choice. Explicit arguments override saved values; `--with-ui` reverses `--without-ui`. Changing the source tree is reserved to this installer; keep your own development copy elsewhere. Downloads and extraction finish before the installed source tree is synchronized, and a source lock prevents concurrent installations in that directory.

To install from an existing complete source copy instead, run from its root:

```bash
bash deploy/install-update-reinstall-debian.sh \
  --model /path/to/model.gguf \
  --domain ai.example.com
```

On Alpine, first install Bash with `apk add bash`, then use `deploy/install-update-reinstall-alpine.sh` with the same arguments. Reuse the installer to update or reinstall. It preserves the existing API key, reuses the CMake build directory and updates the managed service configuration.

From the root of a complete source copy, as root on Alpine:

```bash
apk add bash
bash deploy/install-update-reinstall-alpine.sh \
  --model /path/to/model.gguf \
  --domain ai.example.com
```

The installer builds the binary, copies the model to `/opt/llama-server-apu/models/model.gguf` and creates the locked `llama-server-apu` account. Both inference and a dedicated Apache instance run as that user, without root. At every web startup, HTTP selects the first available port from **11080** upward and HTTPS independently selects one from **11443** upward, up to 65535. The two ports cannot coincide and skip the private inference port `127.0.0.1:18080`. HTTP redirects permanently to the HTTPS port actually selected. The web listener uses IPv4; availability checks also detect IPv6 conflicts. No local HAProxy is installed. Installation needs enough free space for a second copy of the model. Python 3.13+ is required by the web launcher and is installed from the distribution packages.

By default it creates a self-signed certificate. Supply `--cert /path/fullchain.pem --cert-key /path/privkey.pem` to install an existing certificate. The supplied certificate is copied: copy renewed certificates again by rerunning the installer. Logs are written to `/root/webapp-install.log` and credentials to `/root/webapp-credentials.txt`, both with mode `600`.

## First start

Visit the HTTPS URL printed by the installer, normally `https://YOUR-DOMAIN:11443/`. A self-signed certificate requires browser trust; use `--cert` and `--cert-key` for an existing trusted certificate. Obtain the API key from `/root/webapp-credentials.txt` and enter it when prompted. Keep the credential file private. A loading indication is normal while the model starts.

The expanded sidebar and the General section of the Settings dialog contain the language selector: en-GB, en-US, es-AR, es-ES. The default is en-US. The choice is stored in this browser and in the reload URL. Changing language reloads the application, so save unfinished drafts and settings first. Your own messages, model output, filenames and remote MCP content are not translated.

The installer prints the actual URLs. While the web service is running, `/opt/llama-server-apu/web/ports.json` records `httpPort`, `httpsPort`, `httpUrl` and `httpsUrl`. For example, if 11080 and 11443 are occupied, HTTP can use 11081 and HTTPS 11444. The searches are independent: HTTP can stay at 11080 while HTTPS moves to 11445. They restart from the base ports on each restart; clients and firewalls must use the selected ports. If no port is available, startup fails with an explicit error instead of falling back to 80/443. Ports owned by other processes are never closed.

## Conversations and settings

Start a new chat, choose an available model, enter a message and send it. Stop cancels generation. Continue asks for further output; its button can be enabled in general settings. Reasoning-capable models may show a reasoning block and a control to skip it.

Open conversations appear as tabs above the chat; use the tab bar or the keyboard shortcuts shown in its tooltips to switch, open and close them. The input box understands `/` commands (type `/` to list them) and, when the file-search tool is enabled, `@` mentions of files and folders of the working directory. The working directory is chosen next to the input only when a tool reads it.

Use the sidebar to search, rename, pin, export or delete conversations. Editing a message can branch the history; the fork action creates a separate conversation from a chosen point. Deletion is permanent in the browser database. Export important conversations first.

Settings and MCP servers open as dialogs over the current chat. Settings cover themes (system/light/dark), system instructions, Enter behaviour, file handling, generation statistics, reasoning display, sampling, repetition penalties, agentic limits, tools and developer options. Save changes before leaving. Reset returns to the defaults supplied by `/api/props`.

Conversations and attachments use browser IndexedDB; preferences and the API key use local storage. They are specific to the browser/profile/origin and are not a server-side account backup. Export conversations as ZIP/JSONL and settings as JSON; only ZIP and JSONL conversation files can be imported. Settings export excludes credentials unless you explicitly include sensitive data.

## Files and tools

Attach text, images, audio, video or PDFs according to the selected model's capabilities. Models without vision receive extracted PDF text. Vision models can receive PDF pages as images when enabled. Large images can be resized before sending. Audio recording requires browser permission and an audio-capable model.

Add an MCP server in the MCP Servers dialog using its URL and optional authorization/custom headers. The server must support the Streamable HTTP or WebSocket transport. Inspect available tools, prompts and resources before enabling them. Browser CORS rules apply to direct remote connections; the optional server proxy must be enabled separately. Approve or deny tool requests when prompted. Agentic-turn limits and timeouts are configurable.

Built-in tools are optional server features. Browser JavaScript runs in the existing sandbox worker; symbolic mathematics can load nerdamer there. Enabling a tool does not change the permissions of the operating-system service.

## API

Open `/api/doc/` for the bundled Swagger UI and `/api/doc/openapi.json` for its machine-readable schema. Both remain available while models load and when the chat UI is disabled. Use Swagger's authorization control for protected calls. Only the health routes are public; every other route, including the model list, uses `Authorization: Bearer YOUR-KEY` or `X-Api-Key` when an API key is configured. The interactive documentation includes authentication and examples and works without an external CDN.

| Purpose | Route |
| --- | --- |
| Health | GET /api/health |
| Model list | GET /api/v1/models |
| Chat | POST /api/v1/chat/completions |
| Text completions | POST /api/v1/completions |
| Responses-compatible API | POST /api/v1/responses |
| Anthropic-compatible messages | POST /api/v1/messages |
| Embeddings | POST /api/v1/embeddings |
| Audio transcription | POST /api/v1/audio/transcriptions |
| Server properties | GET /api/props |
| Tokenization | POST /api/tokenize |
| Metrics, when enabled | GET /api/metrics |
| Router loading | POST /api/models/load and /api/models/unload |
| Router download/removal | POST and DELETE /api/models |
| Model status stream | GET /api/models/sse |
| Resume/cancel generation | GET/DELETE /api/v1/stream |

A minimal chat request body is `{"messages":[{"role":"user","content":"Hello"}],"stream":false}`. Router mode also requires the selected model identifier. Some endpoints require a compatible model or an enabling launch flag. Swagger lists aliases and additional routes. API errors include a message and HTTP status; 503 normally means the server is not ready.

Compatible clients must use a base URL ending in `/api/v1`. The interface remains at `/`; the `--api-prefix` argument is restricted to `/api`.

## APU tuning

On a detected integrated GPU, unset options receive an automatic context cap of 8192 tokens (without increasing a smaller training context; `--kv-unified-per-slot N` sizes the context instead when given), a 512-token ubatch, one slot, unified KV cache, disabled secondary RAM prompt cache and a global 512 MiB checkpoint limit. An automatic single-slot configuration uses five HTTP threads. Warm-up includes a prefill as large as the ubatch and a one-token generation path.

Explicit command-line values or their `LLAMA_ARG_*` variables override automatic defaults. Flash Attention, layer distribution and host buffers retain their automatic selection. The model load mode defaults to `auto`: on an integrated GPU the weights are read directly into GPU-accessible memory instead of being memory-mapped, so they are not kept twice (page cache plus GPU allocation). Use `--load-mode mmap|none|mlock|mmap+mlock|dio` to force a mode; `--lazy-mode on|auto|off` controls on-demand reading of very large tensors and is off by default on iGPUs.

- `--parallel 1` favours latency; 2 or 4 may improve aggregate throughput with concurrent requests.
- `--batch-size 2048 --ubatch-size 512` is the starting point. Larger ubatches need more temporary memory.
- `--warmup-tokens -1` selects automatic warm-up, 0 uses minimal warm-up and `--no-warmup` disables it.
- `--cache-type-k q8_0 --cache-type-v q8_0` reduces KV memory with a quality/performance trade-off.

The first generated chunk and the final response include `ttft_ms`, `request_parse_ms`, `tokenization_ms`, `queue_ms` and `prompt_cache_ms` in timings. `--metrics` exposes `time_to_first_token_seconds_total`, `time_to_first_token_requests_total`, `queue_seconds_total`, `tokenization_seconds_total`, `prompt_cache_seconds_total` and the averaged gauges `time_to_first_token_seconds` and `queue_seconds` under `/api/metrics`, together with the upstream counters (prompt tokens excluding cached ones, cached prompt tokens, speculative decoding).

The options `--mmap`, `--no-mmap`, `--mlock` and `--dio` were removed upstream; use `--load-mode` instead. `--tensor-read-lazy` is now `--lazy-mode`. `--host` accepts several comma-separated addresses (the installed service keeps 127.0.0.1).

## Memory and Vulkan

Memory fitting uses Linux MemAvailable and the host's model/context/compute allocations, as well as shared iGPU allocations. AMD sysfs VRAM/GTT information avoids double-counting firmware reservations. Defaults leave 1 GiB on the Vulkan budget and 2 GiB in host RAM; configured cache capacity and 512 MiB of HTTP/loading overhead are also reserved. The fit process reduces an automatic context, then offloads layers, and checks the combined budget before loading.

Controls include `--fit-target MiB`, `--fit-target-host MiB`, `--fit-ctx N`, `--cache-ram N` and `--checkpoint-ram N`. For the last two, 0 disables the cache and -1 removes its limit. `--fit off` explicitly disables the fitting barrier. Checkpoints are evicted before copying a new state to avoid excessive transient allocations.

Pipeline caches are keyed by GPU, driver and Vulkan UUID. The installed service uses `/opt/llama-server-apu/cache/llama.cpp/vulkan`. Otherwise the cache uses XDG_CACHE_HOME or `~/.cache`. `GGML_VK_PIPELINE_CACHE` selects a file; `GGML_VK_DISABLE_PIPELINE_CACHE=1` disables persistence. UMA devices precompile a small group of common pipelines; `GGML_VK_DISABLE_PRECOMPILE=1` disables that, while `GGML_VK_PRECOMPILE=1` enables it on discrete GPUs.

Dispatch sizing uses the current graph's FLOPs, combined with upstream's flush before a node that would exceed the threshold. RDNA 3/3.5 use wave32 generally and wave64 for reductions and im2col; upstream adds int8 cooperative-matrix matrix multiplication for RDNA3/RDNA4, reused descriptor sets and further kernel fusions. Original development observations for a Ryzen AI 7 PRO 350 were 16 GiB reserved VRAM and roughly 23.35 GiB GTT; these figures are not hardcoded. Available budgets remain dynamic.

## Operations

The installed executable is `/usr/local/bin/llama-server-apu` (or `<prefix>/bin/llama-server-apu`). Both systemd and OpenRC use that path. To run the compiled bundle, use `~/IA/Apps/llama-server-apu/llama-server-apu --model /path/to/model.gguf`. For a copy that runs entirely from its own folder, without services, see [Self-contained local build](#self-contained-local-build).

Repeat the same `curl | bash` command for subsequent Debian updates, without repeating `--model`. Sources live in `/opt/llama-server-apu-source` and build/cache files stay in its `_/temp/` directory. `/opt/llama-server-apu/config/install.conf` records the domain, binary prefix and UI selection as data with permissions 600; command-line options override them. The copied model remains at `/opt/llama-server-apu/models/model.gguf`, so the original source model may be moved after installation. Existing API keys and certificates are retained. New certificate paths explicitly replace certificate files. `--without-ui` persists until `--with-ui` is supplied; `--build-only` selects the independent bundle compiler and does not load or overwrite deployment settings. Successful deployment saves the settings.

A failed HTTP download, extraction or incomplete archive stops before synchronizing or running the shared installer. Failed builds do not start service reconfiguration. The source lock covers synchronization and the shared installer; bootstrap temporary directories are cleaned on exit. These mechanisms do not roll back an already completed deployment step if a later service operation fails; rerun the installer after addressing the logged cause.

Rerun the same installer with the same options to update/reinstall. It preserves the API key and existing certificates unless replacement certificate paths are supplied. It overwrites the application-managed Apache/service configuration. Save any local changes to those files before reinstalling. The installer uses only the dedicated web service and does not modify the system Apache configuration or its sites.

| Operation | Debian | Alpine |
| --- | --- | --- |
| Restart inference | systemctl restart llama-server-apu | rc-service llama-server-apu restart |
| Inference log | journalctl -u llama-server-apu | /var/log/llama-server-apu.log |
| Restart HTTPS | systemctl restart llama-server-apu-web | rc-service llama-server-apu-web restart |

The launcher log is `/opt/llama-server-apu/web/startup.log` (plus the systemd journal or `/var/log/llama-server-apu-web.log` on Alpine). Selected URLs are in `/opt/llama-server-apu/web/ports.json` while the web service runs. The installer waits for that file before printing the URLs. Apache logs are in `/var/www/YOUR-DOMAIN-logs/`. Installation logs and credentials are in the two root-only files described above. The service API key lives in `/opt/llama-server-apu/config/api-key.txt` with root ownership and read permission for the service group. Certificate files use the same ownership and mode 640 so the unprivileged web server can read them; installation logs and credentials remain mode 600.

For connection problems, check the service log, DNS, certificate and firewall access to the selected HTTP/HTTPS ports. For GPU access, check the Vulkan driver and the service user's video/render groups. For failed compilation, use a local filesystem and check the distribution's Node.js/CMake versions. Deployment work directories and npm cache are under `_/temp/`; bundle compilation uses a private directory under `/tmp` that is deleted on exit.

## Build without deploying services

After installing the [build requirements](#self-contained-local-build), run this from any directory as your normal user:

```bash
curl -fsSL https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/build/build-local.sh | bash
```

The compiler downloads the sources to a private `/tmp/llama-server-apu-build.XXXXXXXX/` directory, builds the server and chat interface, and saves the complete bundle in `~/IA/Apps/llama-server-apu/`. Downloads, source copies, CMake files, npm dependencies, caches and bundle staging all stay in that temporary directory. It is removed after the verified bundle has been copied, and also on failure or a handled interruption. Compilation does not write to `/opt`, `/usr/local/bin` or root installation logs.

From an existing complete source copy, the Debian entry point also selects this same compiler with:

```bash
bash deploy/install-update-reinstall-debian.sh --build-only
```

The `--build-only` option delegates before deployment setup and does not read saved deployment settings. It accepts the build options `--destination`, `--jobs`, `--without-ui` and `--with-ui`. Use `--without-ui` for the API without chat; Swagger remains available. Start the result with `~/IA/Apps/llama-server-apu/llama-server-apu --model /path/to/model.gguf`.

## Self-contained local build

`build/build-local.sh` compiles llama-server-apu on your own computer and leaves a ready-to-run folder, `~/IA/Apps/llama-server-apu/` by default. It is meant for manual, independent use: it does not need root, installs no systemd or OpenRC service and leaves nothing running in the background. The folder contains everything the program needs, including its own copy of the C library, the Vulkan loader and the installed GPU drivers (Mesa and the proprietary NVIDIA driver), so no library is loaded from any other folder of the system.

Local builds always copy the sources into a private directory under `/tmp`, including when the project is on sshfs, NFS or CIFS. The compiler and package use Linux x86-64 with glibc. All build files and caches are temporary; only the final bundle is kept. Build dependencies must already be installed.

1. Install the build requirements once, as root on Debian:

   ```bash
   apt-get install build-essential cmake ninja-build pkg-config libssl-dev libvulkan-dev glslc spirv-headers mesa-vulkan-drivers nodejs npm rsync curl ca-certificates tar gzip
   ```

   The interface needs Node.js 20.19+ or 22.12+. The script lists anything that is still missing.
2. As your normal user, from the project folder:

   ```bash
   bash build/build-local.sh
   ```

3. Put a GGUF model in `~/IA/Apps/llama-server-apu/models/` (any other path also works) and start the server:

   ```bash
   ~/IA/Apps/llama-server-apu/llama-server-apu --model ~/IA/Apps/llama-server-apu/models/model.gguf
   ```

   Open `http://127.0.0.1:8080/`. The API is under `/api/` and its documentation at `/api/doc/`. Stop the server with Ctrl+C.

| Option | Effect |
| --- | --- |
| `--destination PATH` | Bundle folder instead of `~/IA/Apps/llama-server-apu`. |
| `--jobs N` | Parallel compilation jobs (default: all processors). |
| `--without-ui` / `--with-ui` | Build without or with the chat interface (default: with). |
| `--help` | Show the help. |

| Bundle content | Purpose |
| --- | --- |
| `llama-server-apu` | Launcher; always start the program with it. |
| `bin/llama-server-apu` | The compiled server. |
| `lib/` | Own glibc loader and C library, Vulkan loader, GPU drivers and every other library. |
| `share/vulkan/icd.d/` | Vulkan driver manifests pointing to `lib/`. |
| `models/` | Suggested place for GGUF files. |
| `cache/` | Vulkan pipeline cache, driver shader caches and models downloaded with `-hf`. |

Every option after the launcher goes to the server unchanged, for example `--port 8081`, `--host 0.0.0.0`, `--api-key-file FILE` or `--ssl-key-file FILE --ssl-cert-file FILE` for HTTPS. Without `--api-key` or `--api-key-file` no key is requested, so set one before listening on anything other than 127.0.0.1. `--list-devices` shows the GPUs the bundle can use; if only `llvmpipe` (CPU) appears, no GPU driver was bundled.

Run the script again to update the bundle after changing the sources or after updating the GPU drivers. This is required with NVIDIA, whose bundled copy must match the kernel module. Each build starts from scratch in /tmp and removes its temporary files on exit. Only `bin/`, `lib/`, `share/` and the launcher are replaced; `models/`, `cache/` and anything else you put in the folder are kept. The script refuses to overwrite `bin/`, `lib/` or `share/` in a folder that it did not create.

Limitations:

- The folder can be moved, renamed or copied without rebuilding, also to another computer with the same processor type (with NVIDIA, its kernel driver must be the same version): the launcher finds `lib/` from its own location. The only restriction is that the path must not contain `:` or `;`.
- Compilation targets the processor of the computer that builds it (`-march=native`); use the bundle on that computer.
- The bundle takes several hundred megabytes, mainly LLVM (needed by the Mesa drivers) and the NVIDIA driver libraries.
- Starting `bin/llama-server-apu` directly, without the launcher, would use the system's loader, libraries and Vulkan configuration.
- Video input runs the system `ffmpeg` and `ffprobe` as separate programs (`--video-ffmpeg-dir` selects another folder); they are not part of the bundle.

To check that every loaded library comes from the bundle, list them while the devices are enumerated:

```bash
LD_DEBUG=libs ~/IA/Apps/llama-server-apu/llama-server-apu --list-devices 2>&1 | grep 'calling init:'
```

Every path shown must be inside `~/IA/Apps/llama-server-apu/lib/`.

## Upstream update and measurements

The inherited llama.cpp code was synchronized on 2 October 2026 with upstream commit `254b177` (the original fork dated from 4 August 2026). The APU adaptations of this project were kept and the upstream UI improvements were translated into the four languages.

Comparison on the test laptop (Ryzen AI 7 PRO 350, Radeon 860M, 46 GiB RAM, Debian 13, RADV), same build flags, automatic APU profile, prompt of 1626 tokens plus 128 generated tokens, and a short 32-token chat turn. Values are averages of the second series of three requests of each version (warm Vulkan pipeline cache).

| Model | Version | Prompt (t/s) | Long TTFT (s) | Generation (t/s) | Short TTFT (ms) | Startup (s) | Server RSS (MiB) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Qwen3-4B Q4_K_M | before | 204 | 7.97 | 24.2 (short: 27.3) | 162 | 3.0 | 429 |
| Qwen3-4B Q4_K_M | after | 226 | 7.19 | 23.9 (short: 26.5) | 151 | 2.8 | 125 |
| gpt-oss-20b MXFP4 | before | 182 | 8.96 | 21.9 (short: 22.9) | 337 | 4.8 | 763 |
| gpt-oss-20b MXFP4 | after | 238 | 6.84 | 22.5 (short: 23.1) | 311 | 3.8 | 179 |

Prompt processing and time to first token improve clearly, especially for the MoE model (+31 % prompt speed, −24 % TTFT; dense model +11 % and −10 %). The server process no longer keeps a memory-mapped copy of the model. Generation is faster for the MoE model and 1–3 % slower for the small dense model; that difference does not depend on the load mode and comes from upstream Vulkan changes. Results depend on the model, quantization, driver and BIOS memory split.

## Compatibility and limitations

This version keeps no backward compatibility. It reads only the formats, options and data that the current code and the current llama.cpp converters produce. Anything created by an older version must be recreated: reconvert an old model or download a recent conversion, export important conversations as ZIP or JSONL before updating and import them afterwards, and update scripts that use removed options or routes.

**Models (GGUF).** Only GGUF version 3 files written by a current converter are supported. The following older conversions no longer load, or load with degraded output:

- Any BPE model without the `tokenizer.ggml.pre` key (converted before late April 2024), and files whose pre-tokenizer is named `llama3`, `llama-v3`, `jina-es`, `jina-de`, `glm5` or `llada-moe`.
- DeepSeek V2, V2.5, V3, R1 and Moonlight converted before mid-April 2025 (without the MLA keys).
- The first Qwen3-Next conversions (fused `ssm_in` tensor), Qwen1.5-MoE without expert sizes, Jina-BERT-v2 with a separate FFN gate, RWKV-6 with separate `lerp` tensors, Gemma 2 converted between 27 June and 2 July 2024, Grok-1 converted before August 2025, MiniCPM 1/2 without scale keys, GLM-4.5 without `expert_gating_func` and Nemotron-H MoE without `expert_feed_forward_length`.
- GLM-5.2 and GLM-5.3 without the `indexer_types` key, including the unsloth and antirez uploads available on 2 October 2026.
- Kimi K3 files with a wrong `value_length`, such as the July 2026 unsloth upload.
- 2023 models that store linear RoPE scaling under the old `rope.scale_linear` key (for example LLaMA-2-7B-32K or Vicuna-v1.5-16k): long contexts degrade.
- Gemma 4 converted before 6 April 2026 with `add_bos_token = false`, such as some early community fine-tunes: answers degrade, and multi-turn tool calls with Google's earlier chat template are formatted incorrectly.
- Mistral-Small-3.1 (2503) without an embedded chat template now uses the generic ChatML template.

**Multimodal projectors (mmproj).** Gemma 3 and Qwen2-VL projectors converted before 5 May 2025, and SmolVLM, SmolVLM2 and Idefics3 projectors converted between 22 April and 5 May 2025, no longer load; this includes the ggml-org copies of Gemma 3 4B, Qwen2-VL-2B and SmolVLM2-2.2B published at that time. MiniCPM-Llama3-V 2.5 projectors converted before 16 August 2024 load, but images are processed without slicing.

**Chat templates.** Templates are always rendered with the Jinja engine. The built-in C++ templates, `--jinja` and `--no-jinja` were removed. `--chat-template chatml` still works, and a GGUF without a template uses ChatML.

**Options and environment variables.** Removed options: `--jinja`, `--no-jinja`, `--defrag-thold` (`-dt`), `--webui`, `--no-webui`, `--webui-config`, `--webui-config-file`, `--webui-mcp-proxy` and `--no-webui-mcp-proxy` (use the `--ui…` options), `--no-mmproj` (use `--no-mmproj-auto`), `--swa-checkpoints`, imatrix `--output-format`, the old draft options (`--draft`, `--draft-n`, `--draft-max`, `--draft-min`, `--draft-n-min`, `--spec-ngram-size-n`, `--spec-ngram-size-m`, `--spec-ngram-min-hits`) and the old draft aliases such as `-md`/`--model-draft`, `-ngld`, `-devd`, `-td`, `-ctkd` and `-ctvd` (use the `--spec-draft-…` options). Repeating an option is an error, except `--spec-type`; pass comma-separated values instead. `enable_thinking` and `preserve_reasoning` inside `--chat-template-kwargs` are rejected: use `--reasoning on|off` and `--reasoning-preserve`/`--no-reasoning-preserve`. Removed variables: `LLAMA_ARG_JINJA`, `LLAMA_ARG_DEFRAG_THOLD`, `LLAMA_ARG_DRAFT_MAX`, `LLAMA_ARG_DRAFT_MIN`, the automatic negative variables `LLAMA_ARG_NO_<OPTION>` (set the positive variable to `false`), `HF_ENDPOINT` (use `MODEL_ENDPOINT`) and `MTMD_BACKEND_DEVICE` (now `LLAMA_ARG_MMPROJ_DEVICE`). Importance-matrix files are read only in GGUF format.

**API.** `POST /api/completion` and `POST /api/embedding` were removed; use `/api/completions` and `/api/embeddings`, which run the same handlers. The `deepseek-legacy` value of `reasoning_format`, the request field `reasoning_budget_end_tag` and the response field `reasoning_in_content` were removed. Slot caches saved by earlier versions cannot be restored.

**Library interfaces.** Deprecated functions were removed from `llama.h`, `ggml.h` and `mtmd.h`, as were `llama_chat_apply_template` and `llama_chat_builtin_templates`. This only affects code that links the libraries directly.

**Browser data.** The interface no longer reads data saved by earlier versions: the `LlamacppWebui` IndexedDB database, the `LlamaCppWebui.*` keys, the old `theme` key, old message markers and `context` attachments. Old JSON conversation exports cannot be imported; ZIP and JSONL exports can. MCP servers must use the Streamable HTTP or WebSocket transport; the legacy SSE transport and its automatic fallback were removed.

**Installations made by earlier installer versions.** Saved settings are read only from `/opt/llama-server-apu/config/install.conf`. If an installation lacks that file, the installer starts from the defaults (localhost, `/usr/local`, interface enabled): pass `--domain`, `--prefix` and, if needed, `--without-ui` once. The installer no longer removes the old shared-Apache site (`/etc/apache2/sites-enabled/llama-server-apu.conf` on Debian, `/etc/apache2/conf.d/zz-llama-server-apu.conf` on Alpine) and no longer changes the owner of log files created by that root Apache instance. Delete that site and reload Apache yourself, and delete existing files in `/var/www/YOUR-DOMAIN-logs/` or give them to `llama-server-apu`.

The removal of backward compatibility was compiled without errors on the development workstation; the installers and services were not executed and the interface was not rebuilt there. Mobile layout includes shrinkable flex/grid content, wrapping text and scrollable code/tables. A headless browser measured it at 320, 360, 390, 412 and 430 px in the four languages and both themes, with the conversation, sidebar, settings sections, add menu, model selector and search view open: no horizontal overflow and no clipped content.
