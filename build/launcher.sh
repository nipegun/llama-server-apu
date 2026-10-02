#!/bin/bash

set -euo pipefail

# Entry point of a bundle created by build/build-local.sh. Every path is
# derived from this file's location, so the bundle folder can be moved or
# copied without rebuilding. Libraries, Vulkan drivers and caches stay inside it.
cBundleRoot="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd -P)"
cLoaderName='ld-linux-x86-64.so.2'

fCleanup() {
  :
}

trap fCleanup EXIT

fMain() {
  # The loader splits its library path on ':' and ';'.
  if [[ "${cBundleRoot}" == *':'* || "${cBundleRoot}" == *';'* ]]; then
    printf 'The bundle path must not contain ":" or ";": %s\n' "${cBundleRoot}" >&2
    return 1
  fi
  mkdir -p -- "${cBundleRoot}/cache" || return 1
  # Ignore variables that could load system libraries, drivers or layers.
  unset LD_PRELOAD LD_LIBRARY_PATH VK_ICD_FILENAMES VK_ADD_DRIVER_FILES \
    VK_LAYER_PATH VK_ADD_LAYER_PATH VK_INSTANCE_LAYERS VK_LOADER_LAYERS_ENABLE
  export VK_DRIVER_FILES="${cBundleRoot}/share/vulkan/icd.d"
  export VK_LOADER_LAYERS_DISABLE='~all~'
  # Vulkan pipeline, shader and model download caches.
  export XDG_CACHE_HOME="${cBundleRoot}/cache"
  # /proc/self/exe will name the loader, so router mode starts its model
  # children through this launcher (see get_server_exec_path).
  export LLAMA_SERVER_APU_LAUNCHER="${cBundleRoot}/llama-server-apu"
  # The bundled glibc loader resolves libraries only from lib/ (no system
  # cache). --library-path is an argument, not an environment variable, so it
  # does not reach external programs such as ffmpeg.
  exec "${cBundleRoot}/lib/${cLoaderName}" --inhibit-cache --library-path "${cBundleRoot}/lib" \
    "${cBundleRoot}/bin/llama-server-apu" "$@"
}

if ! fMain "$@"; then
  exit 1
fi
