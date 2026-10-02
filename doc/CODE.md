# Code map

## Contents

- [Architecture](#architecture)
- [Modules](#modules)
- [Key symbols](#key-symbols)
- [Main flows](#main-flows)
- [Routes and entry points](#routes-and-entry-points)
- [Impact analysis](#impact-analysis)
- [Extension points](#extension-points)
- [Rules and validation](#rules-and-validation)

## Architecture

llama-server-apu is a focused llama.cpp derivative for local language models on x86-64 APUs. It combines Vulkan acceleration, a browser chat interface and an HTTP API, prioritizing low latency for one active request and time to first token (TTFT).

The CMake entry in build/CMakeLists.txt delegates to backend/CMakeLists.txt with an explicit backend binary directory. That subtree retains the original llama.cpp layout so internal includes and public C interfaces continue to work. frontend/ contains the inherited Svelte application and is added to the same build with an explicit binary directory. deploy/ contains distribution entry points and shared installation logic; build/ contains the CMake entry and the self-contained local build; doc/ contains the multilingual project documentation. The OpenAPI schema lives in backend/tools/server/openapi.json alongside the template that embeds it in the server. Deployment build caches and temporary downloads live under _/temp/; bundle compilation uses a private directory under /tmp and removes it on exit.

EditorConfig files live separately in backend/, frontend/, build/ and deploy/, with UTF-8, LF, a final newline and two-space indentation. The vendor indentation exceptions are relative to the backend/ and frontend/ files. Neither CMakeLists.txt nor .editorconfig lives at the project root; files at that root and in doc/ are outside these EditorConfig scopes. The OpenAPI schema uses backend/.editorconfig. Both build scripts pass the build/ source directory to CMake, and the Debian bootstrap requires and copies build/CMakeLists.txt.

**Upstream base.** The inherited code is synchronized with llama.cpp commit `254b177` (2 October 2026, ggml 0.25.3). The original fork was taken from `5788b51` (4 August 2026). The synchronization was a three-way merge (original base → this project, original base → upstream head): files the project never changed were taken from upstream, purged components (other GPU backends, tests, examples, CLI tools, other CPU architectures) stayed purged, and the project adaptations listed below were re-applied where upstream had moved or rewritten the surrounding code.

Inference remains C++17 over llama and ggml, with CPU and Vulkan execution. Static internal libraries, native CPU instructions and link-time optimisation support the APU latency profile. The project adaptations are: (1) an integrated-GPU server profile in `server.cpp`; (2) host+GPU memory fitting in `common/fit.cpp`, which treats RAM and shared GPU allocations as one budget and now also includes the upstream draft/MTP "extra model" and per-stream contexts; (3) a persistent Vulkan pipeline cache, UMA precompilation, RDNA3 subgroup sizes, per-graph submission sizing and a safe memory-budget computation in the Vulkan backend; (4) `MemAvailable` as the CPU backend's free-memory figure; (5) a global context-checkpoint memory limit; (6) end-to-end latency timings (TTFT, parse, tokenization, queue, prompt cache) in responses and Prometheus metrics; (7) the fixed `/api` prefix with bundled Swagger; (8) the four-language UI; (9) the removal of all backward-compatibility code; (10) `LLAMA_SERVER_APU_LAUNCHER` in `get_server_exec_path()` for the relocatable local bundle.

**No backward compatibility.** The project supports only what the current code and today's upstream converters produce. Loaders accept only GGUF version 3 and require the keys and tensor names current converters write; defaults, heuristics and alternative tensor paths that existed only for older conversions were removed from `backend/src/` (models, vocabulary, loader), `backend/tools/mtmd/` and `backend/ggml/src/gguf.cpp`. Code labelled "legacy" upstream is kept only when current converter output still needs it (for example the FFN up/down swap of the LLaVA, MobileVLM, MiniCPM-V and GLM-Edge projectors, the qwen2.5o projector remap, the InternVL tile defaults, per-tokenizer `add_bos` defaults and the EOT/FIM token-text tables). Chat templates are rendered only by the Jinja engine: `llama-chat.cpp`, `llama_chat_apply_template`, `llama_chat_builtin_templates` and the `--jinja`/`--no-jinja` switch are gone. Deprecated declarations were removed from `llama.h`, `ggml.h` and `mtmd.h`, together with deprecated CLI options, environment aliases, the `/completion` and `/embedding` routes, the `deepseek-legacy` reasoning format, browser-data migrations, the MCP SSE transport and the installer's migrations from earlier installations.

Upstream improvements that matter on APUs arrive with the synchronization, notably the default model load mode `auto` (no mmap when an iGPU is used, so weights are not duplicated in the page cache), lazy tensor reads disabled on iGPUs, lower RAM peaks while loading, int8 cooperative-matrix matmul on RDNA3/RDNA4, descriptor-set reuse, more kernel fusions, MoE-aware tile selection and corrected submission batching. The upstream Vulkan source is now split into `ggml-vulkan.cpp`, `ggml-vulkan-buffers.cpp`, `ggml-vulkan-debug.cpp` and shared headers; the project's Vulkan adaptations live in `ggml-vulkan.cpp` and `ggml-vulkan-types.h`.

A dedicated unprivileged Apache instance selects HTTP from 11080 upward and HTTPS independently from 11443 upward on each startup. Both listeners are IPv4; IPv6-only conflicts are also skipped. HTTP redirects to the actual HTTPS port, preserving path and query. Ports cannot coincide or use the internal inference port. No HAProxy is installed. It forwards to the private inference listener at 127.0.0.1:18080. Debian uses systemd; Alpine uses OpenRC. The service account is llama-server-apu with home /opt/llama-server-apu. The account cannot log in interactively. Browser data remains in IndexedDB/localStorage; there is no new server database or user-login system.

The HTTP context enforces /api for all registered APIs while assets remain at /. The UI and model-child forwarding use the same API root. OpenAPI and locally bundled Swagger UI are compiled into a generated header and stay available during model loading, with or without the chat UI. Public endpoints are explicitly included in the authentication/readiness middleware; upstream now keeps the model lists private when an API key is configured. The inference server can listen on several comma-separated `--host` addresses (upstream); the deployment still uses only 127.0.0.1.

Four JSON locale catalogs are imported by the small i18n adapter. en-US is the default; the URL and browser storage select an alternative. fText resolves keys and {pN} placeholders without rewriting user content. Keys are `message` plus the first 12 hexadecimal characters of the SHA-256 of the original upstream English text (interpolations replaced by {p0}, {p1}…), so a later upstream UI can be re-translated deterministically and existing translations are reused. Changing language reloads the current URL so module-level labels are also rebuilt. The PWA manifest is generated in English at build time. Framework callbacks, protocol field names, text sent to the model and inherited symbol contracts keep their required names.

The UI was rebased on the upstream UI of the same date: conversation tabs, a rich chat input with file `@mentions` and `/` commands, an optional working-directory picker, settings and MCP servers as dialogs, faster message rendering, model discovery/download for router mode, a masked API-key field, closable toasts, WEBM input and mobile layout fixes. Four layout corrections were added on top of it: Lucide icons keep their intrinsic size despite the project's global `min-width: 0` rule (`frontend/src/app.css`), table cells keep a 5rem minimum width, and markdown tables no longer use negative inline margins on phones, because the new `content-visibility: auto` on chat messages clipped them (`markdown-content.css`); the settings dialog footer wraps its buttons so long translations fit on phones (`SettingsFooter.svelte`). The fork's UI build pipeline (local npm build, source fingerprint, own `embed.cpp`, never an upstream prebuilt UI) was kept; upstream's new CMake-only embedding was not adopted because it produces the same `ui.h` interface.

The Debian entry point is also a standalone bootstrap for `curl | bash`: it tolerates an unset BASH_SOURCE, downloads the [main-branch source archive](https://github.com/nipegun/llama-server-apu/archive/refs/heads/main.tar.gz) and synchronizes it into `/opt/llama-server-apu-source` without Git. Download/extraction scratch files and persistent build caches live under that source tree's _/temp/. The shared source lock is inherited through FD 9. Subprocesses receive /dev/null on stdin so they cannot consume the installer stream; the initial model prompt explicitly opens /dev/tty. Saved installation settings are parsed as data, never sourced as shell code. An existing full local checkout runs its local shared installer instead of downloading a replacement. The --build-only branch is selected before root checks, source locks, deployment settings, dependency installation or root logs. It delegates to the local build/build-local.sh, or streams that compiler if there is no local copy. The shared installer applies the same early dispatch to local entry points; only deployment continues into /opt.

**Self-contained local bundle.** `build/build-local.sh` is independent of the deployment: it runs as an ordinary user, installs no service and starts nothing. It compiles with the same CMake options as the installer and assembles `~/IA/Apps/llama-server-apu/` (or `--destination`), which must run entirely from that folder without loading any library from elsewhere on the system. Static internal libraries alone cannot achieve this, because the Vulkan loader and the GPU drivers are always shared objects, so the bundle carries its own glibc loader (`lib/ld-linux-x86-64.so.2`), libc, every dependency reported by `ldd`, the x86-64 Vulkan drivers found in the standard manifest directories (Mesa and the proprietary NVIDIA driver) with rewritten manifests, and the glibc NSS modules listed in `/etc/nsswitch.conf`. Drivers also `dlopen()` helper libraries that `ldd` cannot see (for example `libnvidia-glvkspirv`); their names are string literals, so the script scans the binary and the first closure once and adds every name that the x86-64 linker cache resolves. The launcher starts the unmodified binary through the bundled loader (`lib/ld-linux-x86-64.so.2 --inhibit-cache --library-path <bundle>/lib bin/llama-server-apu`) and derives every path from its own location at each start, so no absolute path is recorded and the folder can be moved or copied without rebuilding. `--library-path` is searched before any RPATH/RUNPATH and applies to the drivers' dependencies and to every `dlopen()`, so the copied libraries stay unmodified; as a loader argument rather than LD_LIBRARY_PATH, it does not leak into the system `ffmpeg`/`ffprobe` processes used for video input. Before installing, the bundled loader resolves every file in the same way and the build fails if anything would come from outside `lib/`. Because `/proc/self/exe` then names the loader, the launcher exports `LLAMA_SERVER_APU_LAUNCHER` and `get_server_exec_path()` returns it, so router-mode children also start through the launcher. Every invocation allocates a private `/tmp/llama-server-apu-build.XXXXXXXX/` directory. Local sources are always copied there with rsync; streamed or standalone execution downloads and extracts main there. CMake output, source-relative npm data, compiler caches and bundle staging all stay inside it. TMPDIR, TMP, TEMP, XDG_CACHE_HOME, npm_config_cache, CCACHE_DIR and SCCACHE_DIR point inside that workspace. The EXIT trap removes the entire workspace after verification and copying to the destination, or after an error or a handled SIGINT/SIGTERM. Build dependencies are checked but never installed by this path. The destination is created only after verification; there are no persistent build caches and no --work-dir option.

## Modules

| Module | Path | Responsibility | Depends on | Used by |
| --- | --- | --- | --- | --- |
| Documentation | [README.md](../README.md), [MANUAL.md](MANUAL.md), [CODE.md](CODE.md) and translations | README: languages, overview, screenshots, deploy and build one-liners, documentation links and sponsorship; manual: requirements, installation, builds and use; code map: architecture and development | Project behavior | users, developers, AI models |
| Build | [build/CMakeLists.txt](../build/CMakeLists.txt) | Main build entry (`cmake -S build`) | backend/CMakeLists.txt | deploy, build/build-local.sh |
| Inference | [backend/src/](../backend/src/) | Models, context, KV cache, decoding and load-mode selection | ggml, include | common, server |
| GPU/CPU | [backend/ggml/](../backend/ggml/) | Tensor operations, Vulkan execution (`ggml-vulkan*.cpp/.h`) and CPU kernels | Vulkan, CPU | llama, mtmd |
| Vendored libraries | [backend/vendor/](../backend/vendor/) | `vendor::hash`, `vendor::nlohmann`, `vendor::stb`, `vendor::miniaudio`, `vendor::sheredom`, cpp-httplib and Swagger UI assets | upstream libraries | common, mtmd, server |
| Common | [backend/common/](../backend/common/) | Arguments, memory fitting, tokenization, chat templates and `parsers/` | llama, vendor | server |
| HTTP | [backend/tools/server/server-http.cpp](../backend/tools/server/server-http.cpp) | Authentication, fixed /api prefix, request arrival time, static assets and Swagger | cpp-httplib, llama-ui | server.cpp |
| Executable | [backend/tools/server/CMakeLists.txt](../backend/tools/server/CMakeLists.txt) | Executable target `llama-server-apu`; links the inherited implementation library | llama-server-impl | installer, systemd, OpenRC, local bundle |
| Routes | [backend/tools/server/server.cpp](../backend/tools/server/server.cpp) | Startup, integrated-GPU profile and route registration | server-context, HTTP | main.cpp |
| Context | [backend/tools/server/server-context.cpp](../backend/tools/server/server-context.cpp) | Inference slots, latency stats, checkpoint limit and request handlers | llama-common, mtmd | routes |
| Stats and metrics | [backend/tools/server/server-common.h](../backend/tools/server/server-common.h) | `server_slot_stats` (per request) and `server_metrics` (cumulative), including latency fields | ggml | context, task results |
| Router | [backend/tools/server/server-models.cpp](../backend/tools/server/server-models.cpp) | Model subprocesses (started through `LLAMA_SERVER_APU_LAUNCHER` when set), downloads and request forwarding | HTTP, subproc | routes |
| Multimodal | [backend/tools/mtmd/](../backend/tools/mtmd/) | Image/audio/video encoders and model projectors | ggml, llama, vendor | server-context |
| Chat UI | [frontend/src/](../frontend/src/) | Svelte views, browser storage and API services | Svelte, UI components | browser |
| Locales | [frontend/src/lib/i18n/](../frontend/src/lib/i18n/) | Four JSON catalogs, language selection and selector component | browser storage | UI components, constants |
| UI build | [backend/scripts/ui-assets.cmake](../backend/scripts/ui-assets.cmake) | Build local UI, compress and embed assets | npm, frontend/embed.cpp | frontend/CMakeLists.txt |
| OpenAPI | [backend/tools/server/openapi.json](../backend/tools/server/openapi.json) | API inventory and request schemas | generate-api-docs.py | api-docs.h.in, Swagger UI |
| Debian bootstrap | [deploy/install-update-reinstall-debian.sh](../deploy/install-update-reinstall-debian.sh) | Stream-safe entry, complete archive download, managed source synchronization and shared lock | curl, tar, rsync, flock | curl pipe or local invocation |
| Deploy | [deploy/](../deploy/) | Root installers, Apache and service templates | distribution packages, CMake | production |
| Web startup | [deploy/start-web.py](../deploy/start-web.py) | Select independent ports, render Apache configuration, supervise the unprivileged web process and publish URLs | Python 3.13+, sockets, Apache | llama-server-apu-web service |
| Local bundle build | [build/build-local.sh](../build/build-local.sh) | Download or copy sources into /tmp, build as an ordinary user, collect runtime dependencies, verify and copy the bundle, then remove all temporary files | CMake, Ninja, npm, ldd, ldconfig, readelf, rsync, curl, tar | developer, manual use |
| Bundle launcher | [build/launcher.sh](../build/launcher.sh) | Bundle entry point: derive every path from its own location, confine Vulkan drivers/layers and caches to the bundle and exec the binary through the bundled loader | bash | user (`~/IA/Apps/llama-server-apu/llama-server-apu`) |

## Key symbols

| Symbol | File:line | Purpose |
| --- | --- | --- |
| `llama-server-apu` (CMake) | [backend/tools/server/CMakeLists.txt:68](../backend/tools/server/CMakeLists.txt#L68) | CMake target and installed filename; completion registration and service paths use the same name |
| `llama_server` | [backend/tools/server/server.cpp:169](../backend/tools/server/server.cpp#L169) | Parse startup arguments, apply the integrated-GPU profile and register routes |
| `server_has_integrated_gpu` | [backend/tools/server/server.cpp:53](../backend/tools/server/server.cpp#L53) | Decide whether the selected device is an iGPU |
| `server_http_context::init` | [backend/tools/server/server-http.cpp:112](../backend/tools/server/server-http.cpp#L112) | Prepare HTTP listeners, authentication, UI and API documentation |
| `server_http_context::get` | [backend/tools/server/server-http.cpp:697](../backend/tools/server/server-http.cpp#L697) | Register GET handlers under /api and stamp request arrival |
| `server_routes::init_routes` | [backend/tools/server/server-context.cpp:4787](../backend/tools/server/server-context.cpp#L4787) | Construct inference request handlers |
| `server_slot::update_latency_stats` | [backend/tools/server/server-context.cpp:541](../backend/tools/server/server-context.cpp#L541) | Decompose TTFT into parse, tokenization, queue and prompt-cache time at the first token |
| `enforce_checkpoint_memory_limit` | [backend/tools/server/server-context.cpp:2365](../backend/tools/server/server-context.cpp#L2365) | Evict the oldest context checkpoints to respect `--checkpoint-ram` |
| `server_slot_stats` | [backend/tools/server/server-common.h:372](../backend/tools/server/server-common.h#L372) | Per-request counters, timings and latency fields; `to_json` produces `timings` |
| `server_metrics` | [backend/tools/server/server-common.h:472](../backend/tools/server/server-common.h#L472) | Cumulative and bucketed metrics; `add_latency` accumulates TTFT and queue time |
| `server_task_result_metrics::to_metrics` | [backend/tools/server/server-task.cpp:1521](../backend/tools/server/server-task.cpp#L1521) | Render Prometheus text, including the latency counters and gauges |
| `server_models::proxy_request` | [backend/tools/server/server-models.cpp:1556](../backend/tools/server/server-models.cpp#L1556) | Forward to a model child preserving the API path |
| `get_server_exec_path` | [backend/tools/server/server-models.cpp:428](../backend/tools/server/server-models.cpp#L428) | Executable for router-mode children; `LLAMA_SERVER_APU_LAUNCHER` (exported by the bundle launcher) takes precedence over `/proc/self/exe` |
| `common_fit_params` | [backend/common/fit.cpp:1006](../backend/common/fit.cpp#L1006) | Fit parameters to host/GPU memory budgets, including an optional draft/MTP model |
| `common_get_amd_apu_memory_data` | [backend/common/fit.cpp:50](../backend/common/fit.cpp#L50) | Read AMD VRAM carveout and GTT usage from sysfs |
| `llama_model_base::load_tensors` | [backend/src/llama-model.cpp:1497](../backend/src/llama-model.cpp#L1497) | Resolve load mode `auto` (no mmap on devices without mmap support, such as iGPUs) |
| `ggml_vk_pipeline_cache_init` | [backend/ggml/src/ggml-vulkan/ggml-vulkan.cpp:53](../backend/ggml/src/ggml-vulkan/ggml-vulkan.cpp#L53) | Load the persistent Vulkan pipeline cache |
| `ggml_vk_precompile_common_pipelines` | [backend/ggml/src/ggml-vulkan/ggml-vulkan.cpp:4184](../backend/ggml/src/ggml-vulkan/ggml-vulkan.cpp#L4184) | Precompile shape-independent pipelines on UMA devices |
| `fBuildUi` | [backend/scripts/ui-assets.cmake:9](../backend/scripts/ui-assets.cmake#L9) | Rebuild when source content changes |
| `fGetLocale` | [frontend/src/lib/i18n/index.ts:34](../frontend/src/lib/i18n/index.ts#L34) | Read the selected locale |
| `fText` | [frontend/src/lib/i18n/index.ts:38](../frontend/src/lib/i18n/index.ts#L38) | Resolve catalog strings and positional placeholders |
| `fSetLocale` | [frontend/src/lib/i18n/index.ts:45](../frontend/src/lib/i18n/index.ts#L45) | Persist language and reload the current view |
| `fReservePort` | [deploy/start-web.py:40](../deploy/start-web.py#L40) | Find a free port and retain reservation sockets |
| `fWriteConfiguration` | [deploy/start-web.py:77](../deploy/start-web.py#L77) | Render the chosen ports and HTTPS redirect |
| `fRunWeb` | [deploy/start-web.py:99](../deploy/start-web.py#L99) | Run and supervise Apache, retry bind races and publish URLs |
| `fDownloadSources` | [deploy/install-update-reinstall-debian.sh:43](../deploy/install-update-reinstall-debian.sh#L43) | Download and synchronize the complete main snapshot |
| `fLockInstallation` | [deploy/install-common.sh:54](../deploy/install-common.sh#L54) | Reuse or acquire the source installation lock |
| `fLoadInstallationSettings` | [deploy/install-common.sh:80](../deploy/install-common.sh#L80) | Restore installed model and saved defaults |
| `fSaveInstallationSettings` | [deploy/install-common.sh:111](../deploy/install-common.sh#L111) | Persist successful deployment settings |
| `fMain (installer)` | [deploy/install-common.sh:295](../deploy/install-common.sh#L295) | Dispatch --build-only to the bundle compiler before deployment setup; otherwise deploy as root |
| `fLocateSources` | [build/build-local.sh:93](../build/build-local.sh#L93) | Locate a full local source copy or select remote compilation |
| `fCleanup` | [build/build-local.sh:29](../build/build-local.sh#L29) | Remove the private /tmp build directory on exit |
| `fPrepareDestination` | [build/build-local.sh:153](../build/build-local.sh#L153) | Validate the bundle directory and refuse managed entries not created by the script |
| `fPrepareWorkDirectories` | [build/build-local.sh:172](../build/build-local.sh#L172) | Allocate a private /tmp directory, isolate caches and copy or download sources |
| `fAddVulkanDrivers` | [build/build-local.sh:308](../build/build-local.sh#L308) | Bundle x86-64 Vulkan drivers and rewrite their manifests to `../../../lib/` |
| `fAddRuntimeLoadedLibraries` | [build/build-local.sh:364](../build/build-local.sh#L364) | Add libraries loaded with `dlopen()` whose names appear as strings |
| `fCopyLibraries` | [build/build-local.sh:392](../build/build-local.sh#L392) | Copy each real file once, unmodified, and create the name symlinks |
| `fCreateBundle` | [build/build-local.sh:411](../build/build-local.sh#L411) | Stage the loader, libraries, drivers, unmodified binary and launcher |
| `fVerifyBundle` | [build/build-local.sh:438](../build/build-local.sh#L438) | Resolve every file as the launcher does and fail if anything would come from outside `lib/` |
| `fInstallBundle` | [build/build-local.sh:471](../build/build-local.sh#L471) | Synchronize `bin/`, `lib/`, `share/` and the launcher, preserving `models/` and `cache/` |
| `fMain (local build)` | [build/build-local.sh:483](../build/build-local.sh#L483) | Run the local build and bundle workflow |
| `fMain (bundle launcher)` | [build/launcher.sh:17](../build/launcher.sh#L17) | Derive paths from its location, set the bundle environment and exec `bin/llama-server-apu` through `lib/ld-linux-x86-64.so.2` |
| `fMain (OpenAPI)` | [backend/scripts/generate-api-docs.py:113](../backend/scripts/generate-api-docs.py#L113) | Generate the static route inventory in backend/tools/server/openapi.json |

## Main flows

1. **Build:** build/CMakeLists.txt → backend targets → vendor libraries → frontend/CMakeLists.txt → fBuildUi → npm ci/build → frontend/embed.cpp → llama-ui → llama-server-apu. Source fingerprints include locale JSON; failed builds stop instead of silently embedding stale/upstream UI assets. Upstream unity builds speed up the C++ compilation.
2. **Install/update:** Debian streamed entry → fBootstrapDependencies → fDownloadSources → source lock/archive/extraction/rsync → shared fMain (same lock) → fLoadInstallationSettings → fParseArguments and optional /dev/tty model prompt → fInstallDependencies → fBuild → fPrepareAccount → fPrepareCertificate → fConfigureServices → fShowUrls → fSaveInstallationSettings. Local complete source copies skip the bootstrap download. Every fallible shell step explicitly propagates failure because fMain is called through an if condition. Root log/credential/settings files use mode 600. Repeats preserve the copied model, certificates, API key, domain, prefix, UI choice and build cache.
3. **Startup:** llama_server → server_has_integrated_gpu → integrated-GPU profile (8192 context unless `-c` or `--kv-unified-per-slot`, 512 ubatch, one slot, unified KV, no RAM prompt cache, 512 MiB checkpoints, prefill warm-up) → host reserve → common_fit_params (host+GPU budget, draft/MTP model) → model load (load mode `auto`: no mmap on the iGPU) → Vulkan pipeline cache and UMA precompilation → warm-up → HTTP listeners.
4. **Chat:** Svelte ChatService → /api/v1/chat/completions → HTTP auth/readiness (arrival timestamp) → route handler (tokenization timestamp) → server queue (queued timestamp) → slot selection/prompt cache → llama decode/Vulkan → first token → update_latency_stats → JSON or SSE with `timings` → browser message store. Router mode forwards the prefixed path to a child model process.
5. **Metrics:** slot release → metrics_on_prediction → server_metrics::add_latency → `/api/metrics` → to_metrics (Prometheus text; cached while the server sleeps).
6. **Resume/stop:** browser stream identity → /api/v1/stream or /api/v1/streams/lookup → local replay buffer or model-child proxy → replay/cancel. The conversation-to-model mapping and byte offset semantics are retained.
7. **Language:** selector → fSetLocale → localStorage plus lang query parameter → reload → fReadLocale → translated components and module-level settings. Content stored as user conversations remains unchanged.
8. **API docs:** source route registration → generate-api-docs.py → backend/tools/server/openapi.json → CMake configure_file → api-docs.h → unauthenticated /api/doc/ assets. Update the semantic descriptions/schemas when handlers change; extracting a route alone cannot describe its complete semantics.
9. **Web startup:** service user → fMain → instance lock → fRunWeb → fReservePort(11080) and fReservePort(11443) → fWriteConfiguration → release reservations → Apache foreground → `/opt/llama-server-apu/web/ports.json`. Each restart searches again. Occupied ports are skipped without stopping their owners; exhausted ranges and non-bind failures produce explicit errors. Certificates are root-owned and group-readable (640), web runtime/logs are service-writable. The system Apache configuration is never used or modified.
10. **Local bundle:** `build/build-local.sh` → fParseArguments → fLocateSources → fCheckDependencies → fPrepareDestination → fPrepareWorkDirectories (private /tmp directory, local source copy or remote archive, isolated caches) → fBuild (same CMake options as the installer, target `llama-server-apu`) → fLoadLibraryCache (`ldconfig -p`, x86-64 entries) → fCreateBundle (the binary's interpreter copied as `lib/ld-linux-x86-64.so.2` → `ldd` of the binary → fAddVulkanDrivers → fAddNameServiceModules → fAddRuntimeLoadedLibraries → fCopyLibraries → unmodified binary and launcher) → fVerifyBundle → fInstallBundle (marker first, then rsync with deletion of `bin/`, `lib/`, `share/`, then the launcher) → fCleanup removes the entire temporary directory, also on failure or a handled interruption. At runtime: `<bundle>/llama-server-apu` → launcher fMain (paths from its own location) → `VK_DRIVER_FILES`, `VK_LOADER_LAYERS_DISABLE=~all~`, `XDG_CACHE_HOME`, `LLAMA_SERVER_APU_LAUNCHER` → exec `lib/ld-linux-x86-64.so.2 --inhibit-cache --library-path <bundle>/lib bin/llama-server-apu` → bundled libc, Vulkan loader and drivers. Router children: get_server_exec_path → launcher.

## Routes and entry points

| Route/command | Handler | File |
| --- | --- | --- |
| `POST /api/models` | `models_routes->post_router_models` | `backend/tools/server/server.cpp` |
| `POST /api/models/load` | `models_routes->post_router_models_load` | `backend/tools/server/server.cpp` |
| `POST /api/models/unload` | `models_routes->post_router_models_unload` | `backend/tools/server/server.cpp` |
| `GET /api/models/sse` | `models_routes->get_router_models_sse` | `backend/tools/server/server.cpp` |
| `DELETE /api/models` | `models_routes->del_router_models` | `backend/tools/server/server.cpp` |
| `GET /api/health` (public) | `routes.get_health` | `backend/tools/server/server.cpp` |
| `GET /api/v1/health` (public) | `routes.get_health` | `backend/tools/server/server.cpp` |
| `GET /api/metrics` | `routes.get_metrics` | `backend/tools/server/server.cpp` |
| `GET /api/props` | `routes.get_props` | `backend/tools/server/server.cpp` |
| `POST /api/props` | `routes.post_props` | `backend/tools/server/server.cpp` |
| `GET /api/models` | `routes.get_models` | `backend/tools/server/server.cpp` |
| `GET /api/v1/models` | `routes.get_models` | `backend/tools/server/server.cpp` |
| `POST /api/completions` | `routes.post_completions` | `backend/tools/server/server.cpp` |
| `POST /api/v1/completions` | `routes.post_completions_oai` | `backend/tools/server/server.cpp` |
| `POST /api/chat/completions` | `routes.post_chat_completions` | `backend/tools/server/server.cpp` |
| `POST /api/v1/chat/completions` | `routes.post_chat_completions` | `backend/tools/server/server.cpp` |
| `POST /api/v1/chat/completions/control` | `routes.post_control` | `backend/tools/server/server.cpp` |
| `POST /api/v1/responses` | `routes.post_responses_oai` | `backend/tools/server/server.cpp` |
| `POST /api/responses` | `routes.post_responses_oai` | `backend/tools/server/server.cpp` |
| `POST /api/v1/audio/transcriptions` | `routes.post_transcriptions_oai` | `backend/tools/server/server.cpp` |
| `POST /api/audio/transcriptions` | `routes.post_transcriptions_oai` | `backend/tools/server/server.cpp` |
| `POST /api/v1/messages` | `routes.post_anthropic_messages` | `backend/tools/server/server.cpp` |
| `POST /api/infill` | `routes.post_infill` | `backend/tools/server/server.cpp` |
| `POST /api/embeddings` | `routes.post_embeddings` | `backend/tools/server/server.cpp` |
| `POST /api/v1/embeddings` | `routes.post_embeddings_oai` | `backend/tools/server/server.cpp` |
| `POST /api/rerank` | `routes.post_rerank` | `backend/tools/server/server.cpp` |
| `POST /api/reranking` | `routes.post_rerank` | `backend/tools/server/server.cpp` |
| `POST /api/v1/rerank` | `routes.post_rerank` | `backend/tools/server/server.cpp` |
| `POST /api/v1/reranking` | `routes.post_rerank` | `backend/tools/server/server.cpp` |
| `POST /api/tokenize` | `routes.post_tokenize` | `backend/tools/server/server.cpp` |
| `POST /api/detokenize` | `routes.post_detokenize` | `backend/tools/server/server.cpp` |
| `POST /api/apply-template` | `routes.post_apply_template` | `backend/tools/server/server.cpp` |
| `POST /api/chat/completions/input_tokens` | `routes.post_chat_completions_tok` | `backend/tools/server/server.cpp` |
| `POST /api/v1/chat/completions/input_tokens` | `routes.post_chat_completions_tok` | `backend/tools/server/server.cpp` |
| `POST /api/responses/input_tokens` | `routes.post_responses_tok_oai` | `backend/tools/server/server.cpp` |
| `POST /api/v1/responses/input_tokens` | `routes.post_responses_tok_oai` | `backend/tools/server/server.cpp` |
| `POST /api/v1/messages/count_tokens` | `routes.post_anthropic_count_tokens` | `backend/tools/server/server.cpp` |
| `GET /api/lora-adapters` | `routes.get_lora_adapters` | `backend/tools/server/server.cpp` |
| `POST /api/lora-adapters` | `routes.post_lora_adapters` | `backend/tools/server/server.cpp` |
| `GET /api/slots` | `routes.get_slots` | `backend/tools/server/server.cpp` |
| `POST /api/slots/:id_slot` | `routes.post_slots` | `backend/tools/server/server.cpp` |
| `GET /api/v1/stream` | `stream_get_h` | `backend/tools/server/server.cpp` |
| `POST /api/v1/streams/lookup` | `streams_lookup_h` | `backend/tools/server/server.cpp` |
| `DELETE /api/v1/stream` | `stream_delete_h` | `backend/tools/server/server.cpp` |
| `GET /api/cors-proxy` | `proxy_handler_get` | `backend/tools/server/server.cpp` |
| `POST /api/cors-proxy` | `proxy_handler_post` | `backend/tools/server/server.cpp` |
| `GET /api/tools` | `tools.handle_get` | `backend/tools/server/server.cpp` |
| `POST /api/tools` | `tools.handle_post` | `backend/tools/server/server.cpp` |
| `GET /api/doc/`, `/api/doc/openapi.json`, `/api/doc/swagger-ui*` | `server_http_context::init` | `backend/tools/server/server-http.cpp` |
| `GET /api/doc` | HTTP 301 → `/api/doc/` | `backend/tools/server/server-http.cpp` |
| `POST /api/predict` (GCP) | `register_gcp_compat` | `backend/tools/server/server-http.cpp` |
| `/#/`, `/#/chat/:id`, `/#/search` (settings and MCP servers open as dialogs) | Svelte hash router | `frontend/src/routes/` |
| `curl -fsSL https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/deploy/install-update-reinstall-debian.sh` → `bash [-s -- OPTIONS]` | `fMain` → `fDownloadSources` → shared installer | `deploy/install-update-reinstall-debian.sh` |
| `cmake --build _/temp/build --target llama-server-apu`, `_/temp/build/bin/llama-server-apu` | `main` → `llama_server` | `backend/tools/server/CMakeLists.txt`, `backend/tools/server/main.cpp` |
| `deploy/install-update-reinstall-debian.sh` / `deploy/install-update-reinstall-alpine.sh` | `fMain` | `deploy/install-common.sh` |
| `llama-server-apu-web`, `python3 -B /opt/llama-server-apu/config/start-web.py --show-urls` | `fMain`, `fShowUrls` | `deploy/start-web.py` |
| `python3 backend/scripts/generate-api-docs.py` | `fMain` | `backend/scripts/generate-api-docs.py` |
| `build/build-local.sh [--destination PATH] [--jobs N] [--without-ui\|--with-ui]` | `fMain` | `build/build-local.sh` |
| `curl .../build/build-local.sh \| bash`, `deploy/install-update-reinstall-debian.sh --build-only` | `fMain` | `build/build-local.sh`, `deploy/install-update-reinstall-debian.sh` |
| `~/IA/Apps/llama-server-apu/llama-server-apu [SERVER OPTIONS]` | `fMain` → `main` → `llama_server` | `build/launcher.sh`, `backend/tools/server/main.cpp` |

The OpenAPI document contains request schemas, errors, authentication and streaming response types. Only the health routes and the documentation assets are public; since the upstream synchronization the model lists also require the API key when one is configured. GCP mode can configure health/prediction suffixes under /api; these variable suffixes are described separately from the static inventory. UI hash navigation is client-side; static assets and documentation are not inference operations.

## Impact analysis

| Component | Affected behaviour |
| --- | --- |
| HTTP prefix/middleware | Every client, static UI access, public health, Swagger and model-child forwarding; keep public/readiness paths aligned with `PUBLIC_ENDPOINTS` in `frontend/src/lib/constants/pwa.constants.ts`. |
| common/fit.cpp, src load mode and ggml Vulkan | Model loading, memory pressure, context/offload choices, startup and inference latency. Upstream merges touching `common_params_fit_impl`, `ggml-vulkan.cpp` or `ggml-vulkan-types.h` must re-apply the project adaptations listed in the architecture. |
| Vulkan submission sizing | Prefill and decode throughput; the per-graph FLOP estimate and upstream's pre-node flush interact (removing the flush was measured as slower). |
| server_slot_stats / server_metrics | `timings` JSON of every completion, the first streamed chunk and `/api/metrics`; keep `to_json`, `add_latency` and `to_metrics` consistent. |
| frontend API constants and stores | Initial chat, reconnection, cancellation, model status, MCP proxy and PWA caching. |
| Locale catalogs and adapter | All translated labels, accessibility text, settings and dates; keys are hashes of the upstream English text, so changing an English source string changes its key in all four catalogs. |
| CMake and UI provisioning | Paths, vendor targets, dependency discovery, generated headers and binary assets; old build caches must not be reused after relocation or an upstream synchronization. |
| Debian bootstrap and saved settings | Updates replace the managed source snapshot while excluding _/temp/. Keep the downloaded wrapper and archive compatible, preserve lock inheritance/cleanup and validate persisted values before use. The --build-only dispatch must precede every deployment side effect. |
| Deployment templates | Port selection on every web restart, redirects, runtime URL publication, service isolation, certificates and streaming timeouts; templates are copied by the installer. |
| Model loaders (`backend/src/models/`, `llama-vocab.cpp`, `llama-model-loader.cpp`, `tools/mtmd/clip.cpp`) | Which GGUF and mmproj files load. Do not reintroduce defaults for missing keys, alternative tensor names or format versions for older conversions; when a current converter omits a key, keep the default and document why. |
| Local bundle (`build/`) | Temporary file isolation and cleanup for local and streamed compilation; only the completed bundle persists. Whether the bundle runs without system libraries. New runtime dependencies (a linked library, a driver, a `dlopen()` target built at run time) must be collected by the script; fVerifyBundle must keep failing on any path outside `lib/`. Changing the bundle layout requires the launcher, the manifest rewrite (`../../../lib/`), `cLoaderName` and fInstallBundle to change together; `get_server_exec_path` must keep honouring `LLAMA_SERVER_APU_LAUNCHER` after upstream synchronizations. GPU driver updates require running the script again, because the proprietary NVIDIA userspace must match the kernel module. |
| OpenAPI generator | Swagger coverage and CODE route inventory; regenerate the schema and update these documents after route changes. |

## Extension points

**Add an API:** implement the handler in the relevant server module, register its unprefixed suffix with ctx_http, and leave the fixed /api prefix to the HTTP adapter. Decide whether it belongs in router mode and whether it is public. Extend dDescriptions and request/response schemas in generate-api-docs.py, regenerate backend/tools/server/openapi.json with Python 3.13+, and update the affected module/symbol/flow rows in all three CODE files.

**Add interface text:** compute the key with `message` + the first 12 hex characters of SHA-256 of the English text (interpolations as {p0}, {p1}…), add it to en-GB.json, en-US.json, es-AR.json and es-ES.json, then call fText. Translate displayed enum labels, not protocol identifiers, stored data or text sent to the model. New locales must be added to aLocales and dCatalogs in alphabetical order and to the language labels.

**Synchronize with upstream again:** export the upstream base (`254b177`) and the new upstream head, map `ggml/`, `src/`, `common/`, `include/`, `vendor/`, `tools/server/`, `tools/mtmd/` and `cmake/` to `backend/` and `tools/ui/` to `frontend/`, merge three-way, keep purged components purged, re-apply the adaptations in moved code, remove any backward-compatibility code upstream adds or keeps (deprecated declarations, legacy routes/options/environment aliases, fallbacks for older GGUF/mmproj files, browser-data migrations), re-translate new UI text with the hash keys and rebuild/validate on an APU before replacing the tree.

**Add a latency metric:** add the field to `server_slot_stats`, fill it in `update_latency_stats`, emit it in `server_slot_stats::to_json`, accumulate it in `server_metrics::add_latency` and expose it in `to_metrics`.

**Change deployment:** edit the templates and shared installer together. Keep root execution for installation only; both inference and the dedicated web launcher run as llama-server-apu. Preserve credentials, explicit shell error propagation and redirection to the dynamically selected HTTPS port. The launcher requires Python 3.13+ and publishes live selections in web/ports.json. It scans through 65535, holds reservations while rendering, releases only its own sockets before Apache binds, retries startup bind races up to ten times and reports other errors. A per-instance lock prevents duplicate launchers; shutdown forwards signals to Apache and removes the published ports. An existing certificate is copied, not linked: renewed material must be reinstalled. Distribution package and SSL configuration reference: [Alpine Apache package](https://pkgs.alpinelinux.org/package/v3.23/main/x86_64/apache2-proxy). The documentation UI uses [Swagger UI configuration](https://swagger.io/docs/open-source-tools/swagger-ui/usage/configuration/). The canonical repository is https://github.com/nipegun/llama-server-apu/. Keep its raw Debian entry self-contained: do not dereference BASH_SOURCE[0] without a default or assume install-common.sh is already present. Document streamed and local usage together. The managed source tree is `/opt/llama-server-apu-source`; state remains under /opt/llama-server-apu. Save only explicitly supported settings after success, preserving CLI precedence and --with-ui/--without-ui symmetry.

**Bundle another runtime file or driver:** add its collection to fCreateBundle (resolve the path, then fAddLibrary and fAddDependencies), place data files under `share/` and refer to them with paths relative to the bundle, export any variable the component needs in `build/launcher.sh`, and keep fVerifyBundle unchanged. New script options go in fUsage and fParseArguments and must be documented in the manual and the relevant code-map entries.

## Rules and validation

The temporary-build relocation and early --build-only dispatch were reviewed statically only; no build, installer or tests were run for this change.

The user-authorized naming and formatting exception for inherited code is recorded in `RulesForThisProjectOnly.md`.

The project-specific rules prohibit Git operations and tests; upstream history was only read from a reference clone in `_/temp/upstream/`. The user authorized preserving inherited names/formatting, including public library/framework contracts; new project code uses two spaces and the specified naming prefixes. API, language and deployment obligations still apply. AGENTS.md and global rule files remain unchanged.

The synchronized tree was compiled without errors or warnings on the development workstation and compiled with LTO and the embedded UI on the Ryzen AI 7 PRO 350 test laptop (Radeon 860M, RADV). The UI passed `svelte-check` with no errors and a production Vite build. A headless browser measured it at 320, 360, 390, 412 and 430 px in the four languages and both themes, with the conversation, sidebar, settings sections, add menu, model selector and search view open: no horizontal overflow and no clipped content. The original and synchronized servers were compared on that laptop with the same flags (results in the manual). The removal of backward compatibility checked converter behaviour against upstream `254b177` sources downloaded into `_/temp/upstream/` and compiled every C++ target of `llama-server-apu` (Debug, Vulkan, without the embedded UI) without errors or warnings; the UI was checked for dangling references and consistent locale keys but not rebuilt, because npm cannot install on the workstation's network mount, and the installers and server were not executed. `build/build-local.sh` and `build/launcher.sh` were checked with `bash -n` only, and the `LLAMA_SERVER_APU_LAUNCHER` change in `server-models.cpp` was not compiled; following the project rules, nothing was executed. tests/ is reserved and contains no tests. Further code changes must update README, MANUAL and CODE in all three languages, including affected index rows.
