# Manual de uso

## Índice

- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Primer inicio](#primer-inicio)
- [Conversaciones y ajustes](#conversaciones-y-ajustes)
- [Archivos y herramientas](#archivos-y-herramientas)
- [API](#api)
- [Ajustes de la APU](#ajustes-de-la-apu)
- [Memoria y Vulkan](#memoria-y-vulkan)
- [Mantenimiento](#mantenimiento)
- [Compilar sin desplegar servicios](#compilar-sin-desplegar-servicios)
- [Compilación local autocontenida](#compilación-local-autocontenida)
- [Actualización desde upstream y mediciones](#actualización-desde-upstream-y-mediciones)
- [Compatibilidad y limitaciones](#compatibilidad-y-limitaciones)

## Requisitos

Usa el instalador remoto siguiente o una copia local de las fuentes en el servidor de producción, con un procesador x86-64, una GPU compatible con Vulkan con su controlador y un modelo GGUF (versión 3 del formato) generado por un convertidor actual de llama.cpp. La compilación se optimiza para el procesador donde se realiza. Debian 13 o una instalación actual de Alpine necesitan CMake, compiladores C/C++, las bibliotecas de desarrollo de Vulkan, OpenSSL, Node.js (20.19+ o 22.12+) y npm; los instaladores obtienen los paquetes de la distribución.

El proyecto no mantiene retrocompatibilidad: no se admiten modelos ni proyectores multimodales convertidos con versiones anteriores de llama.cpp, datos del navegador guardados por versiones anteriores de la interfaz, opciones obsoletas ni rutas de API eliminadas. Vuelve a convertir un modelo antiguo o descarga una versión reciente; el [apartado de compatibilidad](#compatibilidad-y-limitaciones) detalla los cambios.

El equipo de código y el servidor de producción son máquinas diferentes. Ejecuta la instalación en producción como **root**. El proyecto no utiliza sudo ni Git.

## Instalación

Ejecuta lo siguiente desde cualquier carpeta, como root en el servidor de producción. La descarga inicial necesita curl y certificados de CA instalados:

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/deploy/install-update-reinstall-debian.sh | bash
```

La entrada Debian descarga una instantánea completa de `main`, sin Git, en `/opt/llama-server-apu-source`. No hace falta una copia local previa. En la primera instalación, si no se indica `--model`, solicita la ruta local del GGUF por `/dev/tty`. Sin terminal, indica los argumentos:

```bash
curl -fsSL https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/deploy/install-update-reinstall-debian.sh | bash -s -- \
  --model /ruta/al/modelo.gguf --domain ia.ejemplo.com
```

La pregunta nunca lee el script descargado por la entrada estándar. Si falta el modelo y no hay terminal, el instalador se detiene con instrucciones. Si no hay dominio guardado ni argumento explícito, se utiliza localhost. El archivo original del modelo se conserva al copiarlo.

Repite el primer comando para actualizar o reinstalar. Actualiza las fuentes y conserva `_/temp/` (compilación y caché de npm), reutiliza el modelo, la clave de API y los certificados, y recupera el dominio, prefijo y opción de interfaz guardados. Los argumentos explícitos tienen prioridad; `--with-ui` revierte `--without-ui`. Esa carpeta de fuentes está gestionada por el instalador; las modificaciones de desarrollo deben hacerse en otra copia. La descarga y extracción terminan antes de sincronizar las fuentes instaladas, y un bloqueo impide instalaciones simultáneas en esa carpeta.

Para instalar desde una copia local completa, desde la raíz del proyecto y como root:

```bash
bash deploy/install-update-reinstall-debian.sh \
  --model /ruta/al/modelo.gguf \
  --domain ia.ejemplo.com
```

En Alpine, instala primero Bash con `apk add bash` y usa `deploy/install-update-reinstall-alpine.sh` con los mismos argumentos. El mismo instalador permite actualizar o reinstalar: conserva la clave de API existente, reutiliza la carpeta de compilación y actualiza la configuración de los servicios que gestiona.

Desde la raíz de una copia completa de las fuentes, como root en Alpine:

```bash
apk add bash
bash deploy/install-update-reinstall-alpine.sh \
  --model /ruta/al/modelo.gguf \
  --domain ia.ejemplo.com
```

El instalador compila el binario, copia el modelo a `/opt/llama-server-apu/models/model.gguf` y crea la cuenta sin acceso interactivo `llama-server-apu`. Tanto la inferencia como una instancia propia de Apache se ejecutan con ese usuario, sin root. En cada arranque web, HTTP elige el primer puerto disponible desde **11080** y HTTPS busca independientemente desde **11443**, incrementando de uno en uno hasta 65535. Los dos puertos no pueden coincidir y excluyen el puerto interno de inferencia `127.0.0.1:18080`. HTTP redirige permanentemente al puerto HTTPS realmente elegido. El servicio web escucha en IPv4; la selección también detecta conflictos con IPv6. No se instala un HAProxy local. Debe haber espacio para una segunda copia del modelo. El lanzador web necesita Python 3.13 o posterior, que se instala desde los paquetes de la distribución.

Se crea un certificado autofirmado de forma predeterminada. Usa `--cert /ruta/fullchain.pem --cert-key /ruta/privkey.pem` para instalar uno existente. El certificado se copia: tras renovarlo, vuelve a ejecutar el instalador para copiar la nueva versión. Los registros se guardan en `/root/webapp-install.log` y las credenciales en `/root/webapp-credentials.txt`, ambos con permisos `600`.

## Primer inicio

Abre la URL HTTPS que muestra el instalador, normalmente `https://TU-DOMINIO:11443/`. Un certificado autofirmado requiere confianza en el navegador; puedes instalar un certificado de confianza con `--cert` y `--cert-key`. Obtén la clave de API de `/root/webapp-credentials.txt` e introdúcela cuando se solicite. Mantén ese archivo privado. El indicador de carga es normal mientras arranca el modelo.

La barra lateral expandida y la sección General del cuadro de diálogo Ajustes contienen el selector de idioma: en-GB, en-US, es-AR y es-ES. El valor predeterminado es en-US. La elección se guarda en el navegador y en la URL de recarga. Cambiar el idioma recarga la aplicación: guarda antes los borradores y ajustes pendientes. No se traducen tus mensajes, las respuestas del modelo, los nombres de archivos ni el contenido remoto de MCP.

El instalador muestra las URLs reales. Mientras el servicio web está en ejecución, `/opt/llama-server-apu/web/ports.json` contiene `httpPort`, `httpsPort`, `httpUrl` y `httpsUrl`. Por ejemplo, si 11080 y 11443 están ocupados, puede elegir HTTP 11081 y HTTPS 11444. Las búsquedas son independientes: HTTP puede quedarse en 11080 mientras HTTPS pasa a 11445. En cada reinicio se vuelve a buscar desde los puertos iniciales; los clientes y el cortafuegos deben usar los puertos elegidos. Si no hay ninguno disponible, el arranque falla con un error explícito, sin volver a 80/443. No se cierran puertos de otros procesos.

## Conversaciones y ajustes

Inicia un chat nuevo, elige un modelo disponible, escribe un mensaje y envíalo. Detener cancela la generación. Continuar solicita más contenido; su botón puede activarse en los ajustes generales. Los modelos de razonamiento pueden mostrar su razonamiento y un control para omitirlo.

Las conversaciones abiertas aparecen como pestañas encima del chat; usa la barra de pestañas o los atajos de teclado que indican sus descripciones emergentes para cambiar entre ellas, abrirlas y cerrarlas. El cuadro de entrada admite comandos `/` (escribe `/` para verlos) y, cuando la herramienta de búsqueda de archivos está activada, menciones `@` de archivos y carpetas de la carpeta de trabajo. La carpeta de trabajo se elige junto al cuadro de entrada solo cuando alguna herramienta la lee.

La barra lateral permite buscar, renombrar, fijar, exportar y eliminar conversaciones. Editar un mensaje puede ramificar el historial; la acción de ramificar crea una conversación independiente desde ese punto. La eliminación es permanente en la base de datos del navegador. Exporta primero las conversaciones importantes.

Los ajustes y los servidores MCP se abren como cuadros de diálogo sobre el chat actual. Los ajustes incluyen temas (sistema/claro/oscuro), instrucciones del sistema, comportamiento de Intro, gestión de archivos, estadísticas de generación, visualización del razonamiento, muestreo, penalizaciones por repetición, límites del agente, herramientas y opciones de desarrollo. Guarda los cambios antes de salir. Restablecer recupera los valores proporcionados por `/api/props`.

Las conversaciones y adjuntos utilizan IndexedDB; las preferencias y la clave de API utilizan el almacenamiento local. Pertenecen a ese navegador, perfil y origen; no constituyen una copia de seguridad en el servidor. Exporta las conversaciones como ZIP/JSONL y los ajustes como JSON; solo se pueden importar archivos de conversaciones ZIP y JSONL. La exportación de ajustes excluye las credenciales salvo que actives la inclusión de datos sensibles.

## Archivos y herramientas

Adjunta texto, imágenes, audio, vídeo o PDF según las capacidades del modelo. Los modelos sin visión reciben el texto extraído del PDF. Los modelos con visión pueden recibir sus páginas como imágenes si activas esa opción. Las imágenes grandes pueden reducirse antes del envío. Grabar audio requiere permiso del navegador y un modelo compatible.

Añade un servidor MCP en el cuadro de diálogo Servidores MCP mediante su URL y, si corresponde, autorización o cabeceras personalizadas. El servidor debe admitir el transporte Streamable HTTP o WebSocket. Revisa las herramientas, instrucciones y recursos antes de activarlos. Las conexiones remotas directas están sujetas a CORS; el proxy opcional del servidor debe activarse por separado. Autoriza o deniega las solicitudes de herramientas cuando se solicite. Puedes configurar los límites de turnos y los tiempos de espera.

Las herramientas integradas son funciones opcionales del servidor. El JavaScript del navegador se ejecuta en el proceso aislado (worker) existente; las matemáticas simbólicas pueden cargar nerdamer en él. Activar una herramienta no cambia los permisos del servicio del sistema operativo.

## API

Abre `/api/doc/` para consultar Swagger y `/api/doc/openapi.json` para descargar su esquema. Ambos funcionan mientras se cargan modelos y cuando se desactiva el chat. Usa el control de autorización de Swagger para las llamadas protegidas. Solo las rutas de salud son públicas; todas las demás, incluida la lista de modelos, utilizan `Authorization: Bearer TU-CLAVE` o `X-Api-Key` cuando hay una clave de API configurada. La documentación interactiva incluye autenticación y ejemplos y funciona sin un CDN externo.

| Función | Ruta |
| --- | --- |
| Salud | GET /api/health |
| Lista de modelos | GET /api/v1/models |
| Chat | POST /api/v1/chat/completions |
| Completados de texto | POST /api/v1/completions |
| API compatible con Responses | POST /api/v1/responses |
| Mensajes compatibles con Anthropic | POST /api/v1/messages |
| Representaciones vectoriales | POST /api/v1/embeddings |
| Transcripción de audio | POST /api/v1/audio/transcriptions |
| Propiedades del servidor | GET /api/props |
| Tokenización | POST /api/tokenize |
| Métricas, si se activan | GET /api/metrics |
| Carga en modo router | POST /api/models/load y /api/models/unload |
| Descarga y eliminación en modo router | POST y DELETE /api/models |
| Flujo de estado de los modelos | GET /api/models/sse |
| Reanudar/cancelar generación | GET/DELETE /api/v1/stream |

Un cuerpo mínimo de chat es `{"messages":[{"role":"user","content":"Hola"}],"stream":false}`. En modo router también debes indicar el identificador del modelo. Algunas rutas necesitan modelos compatibles o parámetros de activación. Swagger contiene los alias y las demás rutas. Los errores incluyen un mensaje y un estado HTTP; 503 suele indicar que el servidor todavía no está preparado.

Los clientes compatibles deben usar una URL base terminada en `/api/v1`. La interfaz sigue en `/`; `--api-prefix` solo admite `/api`.

## Ajustes de la APU

Cuando se detecta una GPU integrada, los parámetros no indicados reciben un contexto automático máximo de 8192 tokens (sin ampliar un contexto de entrenamiento menor; si se indica `--kv-unified-per-slot N`, es este el que determina el tamaño del contexto), un ubatch de 512 tokens, una sola ranura, caché KV unificada, caché secundaria de prompts en RAM desactivada y un límite global de checkpoints de 512 MiB. Con una ranura automática se usan cinco hilos HTTP. El calentamiento incluye un prefill del tamaño del ubatch y la generación de un token.

Los valores explícitos de la línea de órdenes o de sus variables `LLAMA_ARG_*` tienen prioridad sobre los valores automáticos. Flash Attention, la distribución de capas y los buffers del host conservan su selección automática. El modo de carga del modelo es `auto` de forma predeterminada: en una GPU integrada los pesos se leen directamente en memoria accesible por la GPU en lugar de mapearse en memoria, por lo que no se mantienen duplicados (caché de páginas más asignación de la GPU). Usa `--load-mode mmap|none|mlock|mmap+mlock|dio` para forzar un modo; `--lazy-mode on|auto|off` controla la lectura bajo demanda de tensores muy grandes y está desactivado de forma predeterminada en las iGPU.

- `--parallel 1` prioriza la latencia; 2 o 4 pueden mejorar el rendimiento agregado con peticiones simultáneas.
- `--batch-size 2048 --ubatch-size 512` es el punto de partida. Aumentar el ubatch requiere más memoria temporal.
- `--warmup-tokens -1` elige el calentamiento automático; 0 usa el mínimo y `--no-warmup` lo desactiva.
- `--cache-type-k q8_0 --cache-type-v q8_0` reduce la memoria KV con un compromiso de calidad y rendimiento.

El primer fragmento generado y la respuesta final incluyen `ttft_ms`, `request_parse_ms`, `tokenization_ms`, `queue_ms` y `prompt_cache_ms` en sus tiempos (timings). `--metrics` expone `time_to_first_token_seconds_total`, `time_to_first_token_requests_total`, `queue_seconds_total`, `tokenization_seconds_total`, `prompt_cache_seconds_total` y los indicadores promediados `time_to_first_token_seconds` y `queue_seconds` en `/api/metrics`, junto con los contadores de upstream (tokens del prompt sin contar los que están en caché, tokens del prompt en caché y decodificación especulativa).

Las opciones `--mmap`, `--no-mmap`, `--mlock` y `--dio` se han eliminado en upstream; usa `--load-mode` en su lugar. `--tensor-read-lazy` pasa a ser `--lazy-mode`. `--host` admite varias direcciones separadas por comas (el servicio instalado mantiene 127.0.0.1).

## Memoria y Vulkan

El ajuste de memoria consulta MemAvailable de Linux y las asignaciones del modelo, contexto y cómputo del host, además de la memoria compartida de la iGPU. En AMD, sysfs permite distinguir VRAM y GTT para no contar dos veces las reservas del firmware. Los márgenes predeterminados dejan 1 GiB en Vulkan y 2 GiB en RAM; también reservan la capacidad configurada de las cachés y 512 MiB para HTTP y carga. Primero se reduce el contexto automático, después se descargan capas y finalmente se comprueba el presupuesto conjunto.

Los controles son `--fit-target MiB`, `--fit-target-host MiB`, `--fit-ctx N`, `--cache-ram N` y `--checkpoint-ram N`. En los dos últimos, 0 desactiva la caché y -1 elimina el límite. `--fit off` desactiva expresamente la barrera de ajuste. Los checkpoints antiguos se expulsan antes de copiar un estado nuevo para evitar picos de memoria.

La caché de pipelines se identifica por GPU, controlador y UUID de Vulkan. El servicio instalado la guarda en `/opt/llama-server-apu/cache/llama.cpp/vulkan`. En otras ejecuciones usa XDG_CACHE_HOME o `~/.cache`. `GGML_VK_PIPELINE_CACHE` selecciona un archivo y `GGML_VK_DISABLE_PIPELINE_CACHE=1` desactiva la persistencia. En UMA se precompila un grupo pequeño de pipelines; `GGML_VK_DISABLE_PRECOMPILE=1` lo desactiva y `GGML_VK_PRECOMPILE=1` lo activa en GPU discretas.

El tamaño de los envíos utiliza los FLOP del grafo actual, combinados con el vaciado (flush) de upstream antes de un nodo que superaría el umbral. RDNA 3/3.5 usan wave32 en general y wave64 en reducciones e im2col; upstream añade multiplicación de matrices int8 con matrices cooperativas para RDNA3/RDNA4, reutilización de conjuntos de descriptores y más fusiones de kernels. Durante el desarrollo original, un Ryzen AI 7 PRO 350 mostró 16 GiB de VRAM reservada y unos 23,35 GiB de GTT; no son cifras fijadas en el código. Los presupuestos disponibles son dinámicos.

## Mantenimiento

El ejecutable instalado es `/usr/local/bin/llama-server-apu` (o `<prefijo>/bin/llama-server-apu`). Tanto systemd como OpenRC utilizan esa ruta. El paquete compilado se ejecuta con `~/IA/Apps/llama-server-apu/llama-server-apu --model /ruta/al/modelo.gguf`. Para una copia que funciona entera desde su propia carpeta, sin servicios, consulta [Compilación local autocontenida](#compilación-local-autocontenida).

Para actualizar Debian basta con repetir el mismo `curl | bash`, sin volver a indicar `--model`. Las fuentes viven en `/opt/llama-server-apu-source` y la compilación y cachés permanecen en su carpeta `_/temp/`. `/opt/llama-server-apu/config/install.conf` guarda dominio, prefijo del binario y opción de interfaz como datos, con permisos 600; los argumentos explícitos tienen prioridad. El modelo copiado sigue en `/opt/llama-server-apu/models/model.gguf`, por lo que se puede mover el archivo original después de instalar. Se conservan las claves de API y los certificados existentes. Indicar rutas nuevas de certificados solicita reemplazarlos. `--without-ui` se conserva hasta indicar `--with-ui`; `--build-only` selecciona el compilador independiente del paquete y no carga ni sobrescribe los ajustes del despliegue. Los ajustes se guardan al completar correctamente el despliegue.

Un fallo de descarga HTTP, extracción o archivo incompleto detiene el proceso antes de sincronizar o ejecutar el instalador compartido. Si la compilación falla, no se inicia la reconfiguración de servicios. El bloqueo de las fuentes abarca la sincronización y la instalación; las carpetas temporales de descarga se eliminan al salir. Esto no revierte los pasos de despliegue ya completados si falla una operación de servicio posterior: debe repetirse el instalador tras resolver la causa indicada en el registro.

Vuelve a ejecutar el instalador con las mismas opciones para actualizar o reinstalar. Conserva la clave de API y los certificados existentes salvo que proporciones otros. Sobrescribe la configuración de Apache y del servicio que gestiona: guarda previamente tus modificaciones locales. El instalador utiliza únicamente el servicio web propio y no modifica la configuración de Apache del sistema ni sus sitios.

| Operación | Debian | Alpine |
| --- | --- | --- |
| Reiniciar inferencia | systemctl restart llama-server-apu | rc-service llama-server-apu restart |
| Registro de inferencia | journalctl -u llama-server-apu | /var/log/llama-server-apu.log |
| Reiniciar HTTPS | systemctl restart llama-server-apu-web | rc-service llama-server-apu-web restart |

El registro del lanzador está en `/opt/llama-server-apu/web/startup.log`, además del journal de systemd o `/var/log/llama-server-apu-web.log` en Alpine. Las URLs elegidas están en `/opt/llama-server-apu/web/ports.json` mientras el servicio está activo. El instalador espera ese archivo antes de mostrar las URLs. Los registros de Apache están en `/var/www/TU-DOMINIO-logs/`. Los registros de instalación y credenciales están en los dos archivos privados de root descritos antes. La clave del servicio vive en `/opt/llama-server-apu/config/api-key.txt`, con propietario root y lectura para el grupo del servicio. Los certificados tienen el mismo propietario y permisos 640 para que el servidor web sin privilegios pueda leerlos; los registros de instalación y credenciales conservan permisos 600.

Ante problemas de conexión, revisa el registro, DNS, certificado y acceso a los puertos HTTP/HTTPS elegidos en el cortafuegos. Si falla la GPU, revisa Vulkan y los grupos video/render del servicio. Si falla la compilación, usa un sistema de archivos local y revisa las versiones de Node.js y CMake. Las carpetas de trabajo y la caché de npm del despliegue están en `_/temp/`; la compilación del paquete usa una carpeta privada dentro de `/tmp` que se borra al salir.

## Compilar sin desplegar servicios

Después de instalar los [requisitos de compilación](#compilación-local-autocontenida), ejecuta lo siguiente desde cualquier carpeta con tu usuario normal:

```bash
curl -fsSL https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/build/build-local.sh | bash
```

El compilador descarga las fuentes a una carpeta privada `/tmp/llama-server-apu-build.XXXXXXXX/`, compila el servidor y la interfaz de chat y guarda el paquete completo en `~/IA/Apps/llama-server-apu/`. Las descargas, las copias de fuentes, los archivos de CMake, las dependencias de npm, las cachés y el paquete en preparación quedan dentro de esa carpeta temporal. Se elimina después de copiar el paquete verificado, y también si hay un error o una interrupción controlada. La compilación no escribe en `/opt`, `/usr/local/bin` ni en los registros de instalación de root.

Desde una copia completa de las fuentes, la entrada Debian también selecciona este mismo compilador con:

```bash
bash deploy/install-update-reinstall-debian.sh --build-only
```

La opción `--build-only` delega antes de preparar el despliegue y no lee sus ajustes guardados. Acepta las opciones de compilación `--destination`, `--jobs`, `--without-ui` y `--with-ui`. Usa `--without-ui` para la API sin chat; Swagger sigue disponible. Arranca el resultado con `~/IA/Apps/llama-server-apu/llama-server-apu --model /ruta/al/modelo.gguf`.

## Compilación local autocontenida

`build/build-local.sh` compila llama-server-apu en tu propio ordenador y deja una carpeta lista para usar, `~/IA/Apps/llama-server-apu/` por defecto. Está pensado para un uso manual e independiente: no necesita root, no instala servicios de systemd ni de OpenRC y no deja nada ejecutándose en segundo plano. La carpeta contiene todo lo que necesita el programa, incluida su propia copia de la biblioteca de C, el cargador de Vulkan y los controladores de GPU instalados (Mesa y el controlador propietario de NVIDIA), de modo que no se carga ninguna biblioteca desde ninguna otra carpeta del sistema.

La compilación local siempre copia las fuentes a una carpeta privada dentro de `/tmp`, incluso si el proyecto está en sshfs, NFS o CIFS. El compilador y el paquete utilizan Linux x86-64 con glibc. Todos los archivos de compilación y las cachés son temporales; solo se conserva el paquete final. Los requisitos de compilación deben estar instalados previamente.

1. Instala una vez los requisitos de compilación, como root en Debian:

   ```bash
   apt-get install build-essential cmake ninja-build pkg-config libssl-dev libvulkan-dev glslc spirv-headers mesa-vulkan-drivers nodejs npm rsync curl ca-certificates tar gzip
   ```

   La interfaz necesita Node.js 20.19+ o 22.12+. El script indica lo que aún falte.
2. Con tu usuario normal, desde la carpeta del proyecto:

   ```bash
   bash build/build-local.sh
   ```

3. Coloca un modelo GGUF en `~/IA/Apps/llama-server-apu/models/` (también sirve cualquier otra ruta) y arranca el servidor:

   ```bash
   ~/IA/Apps/llama-server-apu/llama-server-apu --model ~/IA/Apps/llama-server-apu/models/model.gguf
   ```

   Abre `http://127.0.0.1:8080/`. La API está bajo `/api/` y su documentación en `/api/doc/`. Detén el servidor con Ctrl+C.

| Opción | Efecto |
| --- | --- |
| `--destination RUTA` | Carpeta del paquete en lugar de `~/IA/Apps/llama-server-apu`. |
| `--jobs N` | Trabajos de compilación en paralelo (por defecto: todos los procesadores). |
| `--without-ui` / `--with-ui` | Compilar sin la interfaz de chat o con ella (por defecto: con ella). |
| `--help` | Mostrar la ayuda. |

| Contenido del paquete | Función |
| --- | --- |
| `llama-server-apu` | Lanzador; arranca siempre el programa con él. |
| `bin/llama-server-apu` | El servidor compilado. |
| `lib/` | Cargador y biblioteca de C propios de glibc, cargador de Vulkan, controladores de GPU y el resto de bibliotecas. |
| `share/vulkan/icd.d/` | Manifiestos de los controladores Vulkan que apuntan a `lib/`. |
| `models/` | Lugar sugerido para los archivos GGUF. |
| `cache/` | Caché de pipelines de Vulkan, cachés de sombreadores de los controladores y modelos descargados con `-hf`. |

Todas las opciones que siguen al lanzador llegan sin cambios al servidor, por ejemplo `--port 8081`, `--host 0.0.0.0`, `--api-key-file ARCHIVO` o `--ssl-key-file ARCHIVO --ssl-cert-file ARCHIVO` para HTTPS. Sin `--api-key` ni `--api-key-file` no se pide clave, así que configura una antes de escuchar en algo distinto de 127.0.0.1. `--list-devices` muestra las GPU que puede usar el paquete; si solo aparece `llvmpipe` (CPU), no se ha incluido ningún controlador de GPU.

Vuelve a ejecutar el script para actualizar el paquete después de cambiar las fuentes o de actualizar los controladores de GPU. Con NVIDIA es obligatorio, porque su copia incluida debe coincidir con el módulo del núcleo. Cada compilación empieza de cero en /tmp y elimina sus temporales al salir. Solo se reemplazan `bin/`, `lib/`, `share/` y el lanzador; `models/`, `cache/` y cualquier otra cosa que pongas en la carpeta se conservan. El script se niega a sobrescribir `bin/`, `lib/` o `share/` en una carpeta que no haya creado él.

Limitaciones:

- La carpeta se puede mover, renombrar o copiar sin recompilar, también a otro ordenador con el mismo tipo de procesador (con NVIDIA, el controlador del núcleo debe ser de la misma versión): el lanzador localiza `lib/` a partir de su propia ubicación. La única restricción es que la ruta no contenga `:` ni `;`.
- La compilación se optimiza para el procesador del ordenador que compila (`-march=native`); usa el paquete en ese ordenador.
- El paquete ocupa varios cientos de megabytes, sobre todo por LLVM (que necesitan los controladores de Mesa) y por las bibliotecas del controlador de NVIDIA.
- Arrancar `bin/llama-server-apu` directamente, sin el lanzador, usaría el cargador, las bibliotecas y la configuración de Vulkan del sistema.
- La entrada de vídeo ejecuta `ffmpeg` y `ffprobe` del sistema como programas independientes (`--video-ffmpeg-dir` elige otra carpeta); no forman parte del paquete.

Para comprobar que todas las bibliotecas cargadas proceden del paquete, enuméralas mientras se detectan los dispositivos:

```bash
LD_DEBUG=libs ~/IA/Apps/llama-server-apu/llama-server-apu --list-devices 2>&1 | grep 'calling init:'
```

Todas las rutas mostradas deben estar dentro de `~/IA/Apps/llama-server-apu/lib/`.

## Actualización desde upstream y mediciones

El código heredado de llama.cpp se sincronizó el 2 de octubre de 2026 con el commit `254b177` de upstream (la bifurcación original databa del 4 de agosto de 2026). Se han conservado las adaptaciones de este proyecto para la APU y las mejoras de la interfaz de upstream se han traducido a los cuatro idiomas.

Comparación en el portátil de pruebas (Ryzen AI 7 PRO 350, Radeon 860M, 46 GiB de RAM, Debian 13, RADV), con las mismas opciones de compilación, el perfil automático de la APU, un prompt de 1626 tokens más 128 tokens generados y un turno de chat corto de 32 tokens. Los valores son medias de la segunda serie de tres peticiones de cada versión (con la caché de pipelines de Vulkan ya caliente).

| Modelo | Versión | Prompt (t/s) | TTFT largo (s) | Generación (t/s) | TTFT corto (ms) | Arranque (s) | RSS del servidor (MiB) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Qwen3-4B Q4_K_M | antes | 204 | 7.97 | 24.2 (corto: 27.3) | 162 | 3.0 | 429 |
| Qwen3-4B Q4_K_M | después | 226 | 7.19 | 23.9 (corto: 26.5) | 151 | 2.8 | 125 |
| gpt-oss-20b MXFP4 | antes | 182 | 8.96 | 21.9 (corto: 22.9) | 337 | 4.8 | 763 |
| gpt-oss-20b MXFP4 | después | 238 | 6.84 | 22.5 (corto: 23.1) | 311 | 3.8 | 179 |

El procesamiento del prompt y el tiempo hasta el primer token mejoran claramente, sobre todo con el modelo MoE (+31 % de velocidad de prompt, −24 % de TTFT; modelo denso: +11 % y −10 %). El proceso del servidor ya no mantiene una copia del modelo mapeada en memoria. La generación es más rápida con el modelo MoE y un 1–3 % más lenta con el modelo denso pequeño; esa diferencia no depende del modo de carga y procede de cambios de Vulkan en upstream. Los resultados dependen del modelo, la cuantización, el controlador y el reparto de memoria configurado en la BIOS.

## Compatibilidad y limitaciones

Esta versión no mantiene retrocompatibilidad. Solo lee los formatos, opciones y datos que producen el código actual y los convertidores actuales de llama.cpp. Todo lo creado con una versión anterior debe volver a crearse: vuelve a convertir un modelo antiguo o descarga una conversión reciente, exporta las conversaciones importantes como ZIP o JSONL antes de actualizar e impórtalas después, y actualiza los scripts que usen opciones o rutas eliminadas.

**Modelos (GGUF).** Solo se admiten archivos GGUF de la versión 3 escritos por un convertidor actual. Las siguientes conversiones antiguas ya no cargan o cargan con una salida degradada:

- Cualquier modelo BPE sin la clave `tokenizer.ggml.pre` (convertido antes de finales de abril de 2024) y los archivos cuyo pre-tokenizador se llama `llama3`, `llama-v3`, `jina-es`, `jina-de`, `glm5` o `llada-moe`.
- DeepSeek V2, V2.5, V3, R1 y Moonlight convertidos antes de mediados de abril de 2025 (sin las claves MLA).
- Las primeras conversiones de Qwen3-Next (tensor `ssm_in` fusionado), Qwen1.5-MoE sin tamaños de expertos, Jina-BERT-v2 con la puerta FFN separada, RWKV-6 con tensores `lerp` separados, Gemma 2 convertido entre el 27 de junio y el 2 de julio de 2024, Grok-1 convertido antes de agosto de 2025, MiniCPM 1/2 sin claves de escala, GLM-4.5 sin `expert_gating_func` y Nemotron-H MoE sin `expert_feed_forward_length`.
- GLM-5.2 y GLM-5.3 sin la clave `indexer_types`, incluidas las versiones de unsloth y antirez disponibles el 2 de octubre de 2026.
- Archivos de Kimi K3 con un `value_length` erróneo, como la versión de unsloth de julio de 2026.
- Modelos de 2023 que guardan el escalado lineal de RoPE en la clave antigua `rope.scale_linear` (por ejemplo, LLaMA-2-7B-32K o Vicuna-v1.5-16k): los contextos largos se degradan.
- Gemma 4 convertido antes del 6 de abril de 2026 con `add_bos_token = false`, como algunos ajustes finos tempranos de la comunidad: las respuestas empeoran y las llamadas a herramientas en varios turnos con la plantilla de chat anterior de Google se formatean mal.
- Mistral-Small-3.1 (2503) sin plantilla de chat integrada usa ahora la plantilla genérica ChatML.

**Proyectores multimodales (mmproj).** Los proyectores de Gemma 3 y Qwen2-VL convertidos antes del 5 de mayo de 2025, y los de SmolVLM, SmolVLM2 e Idefics3 convertidos entre el 22 de abril y el 5 de mayo de 2025, ya no cargan; esto incluye las copias de ggml-org de Gemma 3 4B, Qwen2-VL-2B y SmolVLM2-2.2B publicadas en esas fechas. Los proyectores de MiniCPM-Llama3-V 2.5 convertidos antes del 16 de agosto de 2024 cargan, pero las imágenes se procesan sin dividirlas en fragmentos.

**Plantillas de chat.** Las plantillas se procesan siempre con el motor Jinja. Se han eliminado las plantillas integradas en C++, `--jinja` y `--no-jinja`. `--chat-template chatml` sigue funcionando, y un GGUF sin plantilla usa ChatML.

**Opciones y variables de entorno.** Opciones eliminadas: `--jinja`, `--no-jinja`, `--defrag-thold` (`-dt`), `--webui`, `--no-webui`, `--webui-config`, `--webui-config-file`, `--webui-mcp-proxy` y `--no-webui-mcp-proxy` (usa las opciones `--ui…`), `--no-mmproj` (usa `--no-mmproj-auto`), `--swa-checkpoints`, `--output-format` de imatrix, las opciones antiguas de borrador (`--draft`, `--draft-n`, `--draft-max`, `--draft-min`, `--draft-n-min`, `--spec-ngram-size-n`, `--spec-ngram-size-m`, `--spec-ngram-min-hits`) y los alias antiguos de borrador como `-md`/`--model-draft`, `-ngld`, `-devd`, `-td`, `-ctkd` y `-ctvd` (usa las opciones `--spec-draft-…`). Repetir una opción es un error, salvo `--spec-type`; indica en su lugar valores separados por comas. Se rechazan `enable_thinking` y `preserve_reasoning` dentro de `--chat-template-kwargs`: usa `--reasoning on|off` y `--reasoning-preserve`/`--no-reasoning-preserve`. Variables eliminadas: `LLAMA_ARG_JINJA`, `LLAMA_ARG_DEFRAG_THOLD`, `LLAMA_ARG_DRAFT_MAX`, `LLAMA_ARG_DRAFT_MIN`, las variables negativas automáticas `LLAMA_ARG_NO_<OPCIÓN>` (asigna `false` a la variable positiva), `HF_ENDPOINT` (usa `MODEL_ENDPOINT`) y `MTMD_BACKEND_DEVICE` (ahora `LLAMA_ARG_MMPROJ_DEVICE`). Los archivos de matriz de importancia solo se leen en formato GGUF.

**API.** Se han eliminado `POST /api/completion` y `POST /api/embedding`; usa `/api/completions` y `/api/embeddings`, que ejecutan los mismos manejadores. Se han eliminado el valor `deepseek-legacy` de `reasoning_format`, el campo de petición `reasoning_budget_end_tag` y el campo de respuesta `reasoning_in_content`. Las cachés de ranuras guardadas por versiones anteriores no se pueden restaurar.

**Interfaces de las bibliotecas.** Se han eliminado las funciones obsoletas de `llama.h`, `ggml.h` y `mtmd.h`, así como `llama_chat_apply_template` y `llama_chat_builtin_templates`. Solo afecta al código que enlaza directamente con las bibliotecas.

**Datos del navegador.** La interfaz ya no lee los datos guardados por versiones anteriores: la base IndexedDB `LlamacppWebui`, las claves `LlamaCppWebui.*`, la clave antigua `theme`, los marcadores de mensajes antiguos y los adjuntos `context`. No se pueden importar las exportaciones JSON antiguas de conversaciones; sí las exportaciones ZIP y JSONL. Los servidores MCP deben usar el transporte Streamable HTTP o WebSocket; se han eliminado el transporte SSE antiguo y su recurso automático.

**Instalaciones hechas con versiones anteriores del instalador.** Los ajustes guardados solo se leen de `/opt/llama-server-apu/config/install.conf`. Si una instalación no tiene ese archivo, el instalador parte de los valores predeterminados (localhost, `/usr/local`, interfaz activada): indica una vez `--domain`, `--prefix` y, si hace falta, `--without-ui`. El instalador ya no retira el antiguo sitio del Apache compartido (`/etc/apache2/sites-enabled/llama-server-apu.conf` en Debian, `/etc/apache2/conf.d/zz-llama-server-apu.conf` en Alpine) ni cambia el propietario de los registros creados por esa instancia de Apache que se ejecutaba como root. Elimina tú ese sitio y recarga Apache, y borra los archivos existentes en `/var/www/TU-DOMINIO-logs/` o asígnalos a `llama-server-apu`.

La eliminación de la retrocompatibilidad se ha compilado sin errores en el equipo de desarrollo; allí no se han ejecutado los instaladores ni los servicios, ni se ha recompilado la interfaz. La maquetación móvil incorpora contenido flex/grid que puede reducirse, textos con ajuste de línea y desplazamiento interno en código y tablas. Se ha medido con un navegador sin interfaz a 320, 360, 390, 412 y 430 px en los cuatro idiomas y los dos temas, con la conversación, la barra lateral, las secciones de ajustes, el menú de añadir, el selector de modelo y la búsqueda abiertos: sin desbordamiento horizontal ni contenido recortado.
