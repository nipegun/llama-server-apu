# llama-server-apu

Available README languages:

[en-US](README.md) · [es-AR](README.es-AR.md) · [es-ES](README.es-ES.md)

## What is it

Run local language models on an x86-64 APU with Vulkan acceleration, a browser chat interface and an HTTP API. This specialized llama.cpp derivative focuses on fast responses, especially the time until the first generated token.

## Screenshots

No screenshots are available yet.

## Deploy

On Debian, run this as `root`:

```bash
curl -fsSL https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/deploy/install-update-reinstall-debian.sh | bash
```

## Build

On Debian, with the [build requirements](doc/MANUAL.md#self-contained-local-build) installed, run this as your normal user:

```bash
curl -fsSL https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/build/build-local.sh | bash
```

Downloads and compiles in a temporary directory under `/tmp`, saves the complete bundle in `~/IA/Apps/llama-server-apu/` and removes the temporary files on exit.

## Read the documentation

- [User manual](doc/MANUAL.md): requirements, installation options, local builds and everyday use.
- [Technical documentation](doc/CODE.md): architecture, modules and development guidance.

## Sponsor this project

- **Commission a feature:** [contact me by email](mailto:nipegun@gmail.com?subject=About%20the%20llama-server-apu%20repo).
- **Support my work with a coffee:** [Buy Me a Coffee](https://buymeacoffee.com/nipegun).
- **Contribute regularly:** [GitHub Sponsors](https://github.com/sponsors/nipegun).
