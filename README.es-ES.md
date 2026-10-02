# llama-server-apu

Idiomas disponibles del README:

[en-US](README.md) · [es-AR](README.es-AR.md) · [es-ES](README.es-ES.md)

## Qué es

Ejecuta modelos de lenguaje locales en una APU x86-64 con aceleración Vulkan, una interfaz de chat en el navegador y una API HTTP. Este derivado especializado de llama.cpp se centra en responder rápido, especialmente en reducir el tiempo hasta el primer token generado.

## Capturas de pantalla

Todavía no hay capturas de pantalla disponibles.

## Despliegue

En Debian, ejecuta lo siguiente como `root`:

```bash
curl -fsSL https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/deploy/install-update-reinstall-debian.sh | bash
```

## Compilación

En Debian, con los [requisitos de compilación](doc/MANUAL.es-ES.md#compilación-local-autocontenida) instalados, ejecuta lo siguiente con tu usuario normal:

```bash
curl -fsSL https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/build/build-local.sh | bash
```

Descarga y compila en una carpeta temporal dentro de `/tmp`, guarda el paquete completo en `~/IA/Apps/llama-server-apu/` y elimina los temporales al salir.

## Lee la documentación

- [Manual de uso](doc/MANUAL.es-ES.md): requisitos, opciones de instalación, compilación local y uso cotidiano.
- [Documentación técnica](doc/CODE.es-ES.md): arquitectura, módulos y guía de desarrollo.

## Patrocina este proyecto

- **Encarga una funcionalidad:** [contacta conmigo por correo](mailto:nipegun@gmail.com?subject=Sobre%20el%20repo%20llama-server-apu).
- **Invítame a un café:** [Buy Me a Coffee](https://buymeacoffee.com/nipegun).
- **Aporta periódicamente:** [GitHub Sponsors](https://github.com/sponsors/nipegun).
