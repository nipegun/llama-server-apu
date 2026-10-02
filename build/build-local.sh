#!/bin/bash

set -euo pipefail

# Builds llama-server-apu on this machine and assembles a self-contained,
# relocatable bundle: the binary, its own glibc loader, every shared library it
# needs and the installed Vulkan drivers. Nothing is installed as a service.
cEntryPath="${BASH_SOURCE[0]:-}"
cArchiveUrl='https://github.com/nipegun/llama-server-apu/archive/refs/heads/main.tar.gz'
cBinaryName='llama-server-apu'
cBundleMarker='.llama-server-apu-bundle'
# Fixed name used by build/launcher.sh to start the bundled loader.
cLoaderName='ld-linux-x86-64.so.2'
cLibraryPattern='lib[A-Za-z0-9_.+-]*\.so(\.[0-9]+)*'
vDestination="${HOME}/IA/Apps/llama-server-apu"
vProjectRoot=''
vWorkDirectory=''
vJobs=''
vBuildUi='ON'
vSourceDirectory=''
vBuildDirectory=''
vStagingDirectory=''
vDriverCount=0
# Library name -> path, from the x86-64 entries of the dynamic linker cache.
declare -A dLibraryPaths=()
# Name the bundle must provide -> real file that provides it.
declare -A dBundledNames=()

fCleanup() {
  local vStatus=$?
  # Only remove the private directory allocated by this invocation of mktemp.
  if [[ "${vWorkDirectory}" == /tmp/llama-server-apu-build.* && -d "${vWorkDirectory}" ]]; then
    if ! rm -rf -- "${vWorkDirectory}"; then
      printf 'Could not remove temporary build files: %s\n' "${vWorkDirectory}" >&2
      exit 1
    fi
  fi
  return "${vStatus}"
}

trap fCleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

fFail() {
  printf 'Error: %s\n' "$*" >&2
  return 1
}

fUsage() {
  printf '%s\n' \
    'Build llama-server-apu locally and assemble a self-contained bundle.' \
    'Usage: build/build-local.sh [OPTIONS]' \
    'Also supports curl URL | bash and curl URL | bash -s -- OPTIONS.' \
    'Options:' \
    '  --destination PATH  Bundle directory (default: ~/IA/Apps/llama-server-apu).' \
    '  --jobs N            Parallel build jobs (default: all processors).' \
    '  --without-ui        Build the API without the chat interface.' \
    '  --with-ui           Build the chat interface (default).' \
    '  --help              Display this help.' \
    'Start the result with: <destination>/llama-server-apu --model /path/model.gguf' \
    'The bundle folder can be moved or copied without rebuilding.' \
    'Sources, caches and build files stay in /tmp and are removed on exit.' \
    'Install the build dependencies beforehand; this script needs no root.' \
    'No service is installed and nothing keeps running in the background.'
}

fParseArguments() {
  while (($#)); do
    case "$1" in
      --destination|--jobs)
        (($# >= 2)) || { fFail "Missing value for $1"; return 1; }
        case "$1" in
          --destination) vDestination="$2" ;;
          --jobs) vJobs="$2" ;;
        esac
        shift 2
        ;;
      --without-ui) vBuildUi='OFF'; shift ;;
      --with-ui) vBuildUi='ON'; shift ;;
      *) fFail "Unknown option: $1"; return 1 ;;
    esac
  done
  [[ -z "${vJobs}" || "${vJobs}" =~ ^[1-9][0-9]*$ ]] || { fFail 'Jobs must be a positive integer.'; return 1; }
  [[ -n "${vJobs}" ]] || vJobs="$(getconf _NPROCESSORS_ONLN)" || return 1
  [[ -n "${vDestination}" ]] || { fFail 'The destination cannot be empty.'; return 1; }
  # Accept a quoted ~/ as well as one already expanded by the shell.
  if [[ "${vDestination}" == '~/'* ]]; then
    vDestination="${HOME}/${vDestination:2}"
  fi
}

fLocateSources() {
  local vDirectory
  if [[ -n "${cEntryPath}" && -f "${cEntryPath}" ]]; then
    vDirectory="$(cd -- "$(dirname -- "${cEntryPath}")/.." && pwd -P)" || return 1
    if [[ -f "${vDirectory}/build/CMakeLists.txt" && -f "${vDirectory}/backend/CMakeLists.txt" ]]; then
      vProjectRoot="${vDirectory}"
    fi
  fi
}

fFindLdconfig() {
  local vCandidate
  for vCandidate in /sbin/ldconfig /usr/sbin/ldconfig "$(command -v ldconfig 2>/dev/null || true)"; do
    if [[ -n "${vCandidate}" && -x "${vCandidate}" ]]; then
      printf '%s\n' "${vCandidate}"
      return 0
    fi
  done
  return 1
}

fCheckDependencies() {
  if [[ "$(uname -s)" != 'Linux' || "$(uname -m)" != 'x86_64' ]] || ! getconf GNU_LIBC_VERSION >/dev/null 2>&1; then
    fFail 'Self-contained builds require Linux x86-64 with glibc.'
    return 1
  fi
  local -a aMissing=()
  local vCommand
  local vModule
  local -a aCommands=(cmake ninja cc c++ glslc pkg-config readelf rsync ldd od)
  if [[ -z "${vProjectRoot}" ]]; then
    aCommands+=(curl tar gzip)
  fi
  if [[ "${vBuildUi}" == 'ON' ]]; then
    aCommands+=(node npm gzip)
  fi
  for vCommand in "${aCommands[@]}"; do
    if ! command -v "${vCommand}" >/dev/null 2>&1; then
      aMissing+=("${vCommand}")
    fi
  done
  if ! fFindLdconfig >/dev/null; then
    aMissing+=('ldconfig')
  fi
  if command -v pkg-config >/dev/null 2>&1; then
    for vModule in vulkan openssl SPIRV-Headers; do
      if ! pkg-config --exists "${vModule}"; then
        aMissing+=("${vModule} (pkg-config)")
      fi
    done
  fi
  if (( ${#aMissing[@]} )); then
    printf 'Missing build requirements: %s\n' "${aMissing[*]}" >&2
    printf '%s\n' \
      'On Debian, install them as root with:' \
      '  apt-get install build-essential cmake ninja-build pkg-config libssl-dev libvulkan-dev glslc spirv-headers mesa-vulkan-drivers nodejs npm rsync curl ca-certificates tar gzip' >&2
    return 1
  fi
}

fPrepareDestination() {
  local vEntry
  vDestination="$(realpath -m -- "${vDestination}")" || return 1
  if [[ "${vDestination}" == '/' || "${vDestination}" == "$(realpath -m -- "${HOME}")" || "${vDestination}" == "${vProjectRoot}" ]]; then
    fFail "Refusing to use ${vDestination} as the bundle directory."
    return 1
  fi
  # Only bin/, lib/, share/ and the launcher are replaced. Refuse to touch
  # them unless an earlier run of this script created them.
  if [[ ! -f "${vDestination}/${cBundleMarker}" ]]; then
    for vEntry in bin lib share "${cBinaryName}"; do
      if [[ -e "${vDestination}/${vEntry}" || -L "${vDestination}/${vEntry}" ]]; then
        fFail "${vDestination}/${vEntry} already exists and was not created by this script."
        return 1
      fi
    done
  fi
}

fPrepareWorkDirectories() {
  local vWorkFilesystem
  local vRequired
  vWorkDirectory="$(mktemp -d /tmp/llama-server-apu-build.XXXXXXXX)" || return 1
  if [[ "${vDestination}" == "${vWorkDirectory}" || "${vDestination}" == "${vWorkDirectory}/"* || "${vWorkDirectory}" == "${vDestination}/"* ]]; then
    fFail 'The bundle and temporary build directories must be separate.'
    return 1
  fi
  vWorkFilesystem="$(stat -f -c '%T' -- "${vWorkDirectory}")" || return 1
  case "${vWorkFilesystem}" in
    fuse|fuseblk|nfs|nfs4|cifs|smb2)
      fFail '/tmp must be on a local filesystem for compilation.'
      return 1
      ;;
  esac
  vSourceDirectory="${vWorkDirectory}/source"
  vBuildDirectory="${vWorkDirectory}/build"
  vStagingDirectory="${vWorkDirectory}/bundle-staging"
  export TMPDIR="${vWorkDirectory}/tmp"
  export TMP="${TMPDIR}" TEMP="${TMPDIR}"
  export XDG_CACHE_HOME="${vWorkDirectory}/cache"
  export npm_config_cache="${XDG_CACHE_HOME}/npm"
  export CCACHE_DIR="${XDG_CACHE_HOME}/ccache" SCCACHE_DIR="${XDG_CACHE_HOME}/sccache"
  mkdir -p -- "${vSourceDirectory}" "${vBuildDirectory}" "${TMPDIR}" "${XDG_CACHE_HOME}" \
    "${vStagingDirectory}/bin" "${vStagingDirectory}/lib" \
    "${vStagingDirectory}/share/vulkan/icd.d" || return 1
  if [[ -n "${vProjectRoot}" ]]; then
    # Always build a private copy so source-relative caches also stay in /tmp.
    printf 'Copying sources to %s.\n' "${vSourceDirectory}"
    rsync -a \
      --exclude='/_/' --exclude='/.git/' --exclude='/.agents/' --exclude='/.claude/' \
      --exclude='/.codex/' --exclude='/.aws/' --exclude='/Rules/' --exclude='node_modules/' \
      --exclude='/frontend/dist/' --exclude='/frontend/.svelte-kit/' \
      -- "${vProjectRoot}/" "${vSourceDirectory}/" || return 1
  else
    printf 'Downloading sources to %s.\n' "${vSourceDirectory}"
    curl --fail --silent --show-error --location --retry 3 \
      --connect-timeout 30 --max-time 600 --proto '=https' --proto-redir '=https' \
      --output "${vWorkDirectory}/source.tar.gz" "${cArchiveUrl}" || return 1
    tar -xzf "${vWorkDirectory}/source.tar.gz" --strip-components=1 \
      --no-same-owner --no-same-permissions -C "${vSourceDirectory}" || return 1
  fi
  for vRequired in build/CMakeLists.txt build/launcher.sh backend/CMakeLists.txt backend/tools/server/openapi.json frontend/package.json; do
    if [[ ! -s "${vSourceDirectory}/${vRequired}" ]]; then
      fFail "The source tree is incomplete: ${vRequired}"
      return 1
    fi
  done
}

fBuild() {
  local -a aCmakeArguments=(
    -S "${vSourceDirectory}/build"
    -B "${vBuildDirectory}"
    -DCMAKE_BUILD_TYPE=Release
    -DLLAMA_APU_OPTIMIZED=ON
    -DGGML_VULKAN=ON
    -DGGML_NATIVE=ON
    -DGGML_LTO=ON
    -DBUILD_SHARED_LIBS=OFF
    -DLLAMA_BUILD_UI="${vBuildUi}"
  )
  if [[ ! -f "${vBuildDirectory}/CMakeCache.txt" ]]; then
    aCmakeArguments+=(-G Ninja)
  fi
  cmake "${aCmakeArguments[@]}" || return 1
  cmake --build "${vBuildDirectory}" --target "${cBinaryName}" --parallel "${vJobs}" || return 1
}

fLoadLibraryCache() {
  local vLdconfig
  local vName
  local vPath
  vLdconfig="$(fFindLdconfig)" || return 1
  # Same resolution as dlopen() of a bare name: first x86-64 cache entry.
  while read -r vName vPath; do
    if [[ -z "${dLibraryPaths[${vName}]:-}" ]]; then
      dLibraryPaths["${vName}"]="${vPath}"
    fi
  done < <("${vLdconfig}" -p | sed -n 's/^[[:space:]]*\([^[:space:]]*\) (libc6,x86-64[^)]*) => \(\/.*\)$/\1 \2/p')
  if (( ${#dLibraryPaths[@]} == 0 )); then
    fFail 'The dynamic linker cache lists no x86-64 libraries.'
    return 1
  fi
}

fIsX8664Elf() {
  local pPath="$1"
  local vHeader
  [[ -f "${pPath}" && -r "${pPath}" ]] || return 1
  vHeader="$(od -An -v -tx1 -N20 -- "${pPath}" | tr -d ' \n')" || return 1
  # ELF magic, 64-bit class and e_machine EM_X86_64.
  [[ "${vHeader:0:10}" == '7f454c4602' && "${vHeader:36:4}" == '3e00' ]]
}

fCanResolve() {
  local pPath="$1"
  local vOutput
  fIsX8664Elf "${pPath}" || return 1
  vOutput="$(ldd -- "${pPath}" 2>/dev/null)" || return 1
  [[ "${vOutput}" != *'not found'* ]]
}

fAddLibrary() {
  local pName="$1"
  local pPath="$2"
  local vRealPath
  vRealPath="$(realpath -- "${pPath}")" || return 1
  if ! fIsX8664Elf "${vRealPath}"; then
    return 0
  fi
  if [[ -z "${dBundledNames[${pName}]:-}" ]]; then
    dBundledNames["${pName}"]="${vRealPath}"
  fi
}

fAddDependencies() {
  local pPath="$1"
  local vOutput
  local vName
  local vPath
  # ldd already lists the complete transitive closure of pPath.
  if ! vOutput="$(ldd -- "${pPath}")"; then
    fFail "Cannot list the dependencies of ${pPath}."
    return 1
  fi
  if [[ "${vOutput}" == *'not found'* ]]; then
    printf '%s\n' "${vOutput}" >&2
    fFail "${pPath} has unresolved dependencies."
    return 1
  fi
  while read -r vName vPath; do
    fAddLibrary "${vName}" "${vPath}" || return 1
  done < <(printf '%s\n' "${vOutput}" | sed -n 's/^[[:space:]]*\([^[:space:]]*\) => \(\/[^[:space:]]*\) (0x[0-9a-f]*)$/\1 \2/p')
}

fAddVulkanDrivers() {
  local -A dSeenManifests=()
  local vManifestDirectory
  local vManifest
  local vManifestName
  local vLibraryPath
  local vLibraryName
  local vResolved
  # Same manifest locations the Vulkan loader searches by default.
  for vManifestDirectory in /etc/vulkan/icd.d /usr/local/share/vulkan/icd.d /usr/share/vulkan/icd.d; do
    [[ -d "${vManifestDirectory}" ]] || continue
    for vManifest in "${vManifestDirectory}"/*.json; do
      [[ -f "${vManifest}" ]] || continue
      vManifestName="$(basename -- "${vManifest}")" || return 1
      [[ -z "${dSeenManifests[${vManifestName}]:-}" ]] || continue
      vLibraryPath="$(sed -n '/"library_path"/{s/.*"library_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p;q}' "${vManifest}")" || return 1
      [[ -n "${vLibraryPath}" ]] || continue
      case "${vLibraryPath}" in
        /*) vResolved="${vLibraryPath}" ;;
        */*) vResolved="$(dirname -- "${vManifest}")/${vLibraryPath}" ;;
        *) vResolved="${dLibraryPaths[${vLibraryPath}]:-}" ;;
      esac
      if [[ -z "${vResolved}" ]] || ! fCanResolve "${vResolved}"; then
        printf 'Skipping Vulkan driver %s: no usable x86-64 library %s.\n' "${vManifest}" "${vLibraryPath}"
        continue
      fi
      dSeenManifests["${vManifestName}"]=1
      vLibraryName="$(basename -- "${vLibraryPath}")" || return 1
      fAddLibrary "${vLibraryName}" "${vResolved}" || return 1
      fAddDependencies "${vResolved}" || return 1
      # A library_path containing a slash is relative to the manifest itself.
      sed -e "s|\(\"library_path\"[[:space:]]*:[[:space:]]*\"\)[^\"]*\"|\1../../../lib/${vLibraryName}\"|" \
        "${vManifest}" > "${vStagingDirectory}/share/vulkan/icd.d/${vManifestName}" || return 1
      vDriverCount=$((vDriverCount + 1))
      printf 'Bundling Vulkan driver %s (%s).\n' "${vManifestName}" "${vLibraryName}"
    done
  done
}

fAddNameServiceModules() {
  local vModule
  local vName
  local vPath
  [[ -r /etc/nsswitch.conf ]] || return 0
  # glibc dlopen()s these modules for user and host lookups.
  while read -r vModule; do
    vName="libnss_${vModule}.so.2"
    vPath="${dLibraryPaths[${vName}]:-}"
    if [[ -n "${vPath}" ]] && fCanResolve "${vPath}"; then
      fAddLibrary "${vName}" "${vPath}" || return 1
      fAddDependencies "${vPath}" || return 1
    fi
  done < <(sed -e 's/#.*//' -e '/^[[:space:]]*[A-Za-z_]*:/!d' -e 's/^[[:space:]]*[A-Za-z_]*://' \
    -e 's/\[[^]]*\]//g' -e 's/[[:space:]]\+/\n/g' /etc/nsswitch.conf | sed '/^$/d' | sort -u)
}

fAddRuntimeLoadedLibraries() {
  local pBinary="$1"
  local -a aScanFiles=("${pBinary}")
  local -A dScanned=()
  local vName
  local vFile
  local vCandidate
  local vPath
  # Drivers dlopen() helper libraries that ldd cannot see (for example the
  # NVIDIA SPIR-V compiler). Their names are string literals, so scan the
  # binary and the current closure once and add every match that exists.
  for vName in "${!dBundledNames[@]}"; do
    aScanFiles+=("${dBundledNames[${vName}]}")
  done
  for vFile in "${aScanFiles[@]}"; do
    [[ -z "${dScanned[${vFile}]:-}" ]] || continue
    dScanned["${vFile}"]=1
    while read -r vCandidate; do
      [[ -z "${dBundledNames[${vCandidate}]:-}" ]] || continue
      vPath="${dLibraryPaths[${vCandidate}]:-}"
      [[ -n "${vPath}" ]] || continue
      fCanResolve "${vPath}" || continue
      fAddLibrary "${vCandidate}" "${vPath}" || return 1
      fAddDependencies "${vPath}" || return 1
    done < <(grep -aoE -- "${cLibraryPattern}" "${vFile}" | sort -u)
  done
}

fCopyLibraries() {
  local vLibraryDirectory="${vStagingDirectory}/lib"
  local vName
  local vRealPath
  local vRealName
  # Copies stay unmodified: the loader's --library-path is searched before
  # any RPATH/RUNPATH they carry. Preserved timestamps keep syncs incremental.
  for vName in "${!dBundledNames[@]}"; do
    vRealPath="${dBundledNames[${vName}]}"
    vRealName="$(basename -- "${vRealPath}")" || return 1
    if [[ ! -e "${vLibraryDirectory}/${vRealName}" ]]; then
      cp --preserve=mode,timestamps -- "${vRealPath}" "${vLibraryDirectory}/${vRealName}" || return 1
    fi
    if [[ "${vName}" != "${vRealName}" && ! -e "${vLibraryDirectory}/${vName}" ]]; then
      ln -s -- "${vRealName}" "${vLibraryDirectory}/${vName}" || return 1
    fi
  done
}

fCreateBundle() {
  local vBinary="${vBuildDirectory}/bin/${cBinaryName}"
  local vInterpreter
  local vInterpreterPath
  [[ -x "${vBinary}" ]] || { fFail "The build did not produce ${vBinary}."; return 1; }
  # The loader must come from the same glibc as the bundled libc.
  vInterpreter="$(LC_ALL=C readelf -l -- "${vBinary}" | sed -n 's/^.*\[Requesting program interpreter: \(.*\)\]$/\1/p')" || return 1
  [[ -n "${vInterpreter}" ]] || { fFail "Cannot read the program interpreter of ${vBinary}."; return 1; }
  vInterpreterPath="$(realpath -- "${vInterpreter}")" || return 1
  cp --preserve=mode,timestamps -- "${vInterpreterPath}" "${vStagingDirectory}/lib/${cLoaderName}" || return 1
  fAddDependencies "${vBinary}" || return 1
  fAddVulkanDrivers || return 1
  fAddNameServiceModules || return 1
  fAddRuntimeLoadedLibraries "${vBinary}" || return 1
  fCopyLibraries || return 1
  if (( vDriverCount == 0 )); then
    printf '%s\n' \
      'Warning: no x86-64 Vulkan driver was found; the bundle will only use the CPU.' \
      'Install mesa-vulkan-drivers (or the GPU vendor driver) and run this script again.' >&2
  fi
  # No path is recorded in the binary: the launcher starts it through the
  # bundled loader with lib/ located relative to itself, so the folder can move.
  cp --preserve=mode,timestamps -- "${vBinary}" "${vStagingDirectory}/bin/${cBinaryName}" || return 1
  printf 'llama-server-apu bundle created by build/build-local.sh\n' > "${vStagingDirectory}/${cBundleMarker}" || return 1
  install -m 0755 -- "${vSourceDirectory}/build/launcher.sh" "${vStagingDirectory}/${cBinaryName}" || return 1
}

fVerifyBundle() {
  local vLibraryDirectory="${vStagingDirectory}/lib"
  local vLoader="${vLibraryDirectory}/${cLoaderName}"
  local vFile
  local vOutput
  local vPath
  local vResolved
  # Resolve everything exactly as the launcher does: bundled loader, no
  # system cache and lib/ as the only library path.
  for vFile in "${vStagingDirectory}/bin/${cBinaryName}" "${vLibraryDirectory}"/*; do
    if [[ -L "${vFile}" || ! -f "${vFile}" || "${vFile}" == "${vLoader}" ]]; then
      continue
    fi
    if ! vOutput="$("${vLoader}" --inhibit-cache --library-path "${vLibraryDirectory}" --list "${vFile}" 2>&1)"; then
      printf '%s\n' "${vOutput}" >&2
      fFail "The bundled loader cannot load ${vFile}."
      return 1
    fi
    if [[ "${vOutput}" == *'not found'* ]]; then
      printf '%s\n' "${vOutput}" >&2
      fFail "${vFile} has dependencies missing from the bundle."
      return 1
    fi
    while read -r vPath; do
      vResolved="$(realpath -- "${vPath}")" || return 1
      if [[ "${vResolved}" != "${vLibraryDirectory}/"* ]]; then
        fFail "${vFile} would load ${vResolved} from outside the bundle."
        return 1
      fi
    done < <(printf '%s\n' "${vOutput}" | sed -n 's/^.* => \(\/[^[:space:]]*\) (0x[0-9a-f]*)$/\1/p')
  done
}

fInstallBundle() {
  local vEntry
  mkdir -p -- "${vDestination}" || return 1
  # The marker goes first, so an interrupted copy can be completed later.
  rsync -a -- "${vStagingDirectory}/${cBundleMarker}" "${vDestination}/" || return 1
  for vEntry in bin lib share; do
    rsync -a --delete -- "${vStagingDirectory}/${vEntry}/" "${vDestination}/${vEntry}/" || return 1
  done
  rsync -a -- "${vStagingDirectory}/${cBinaryName}" "${vDestination}/${cBinaryName}" || return 1
  mkdir -p -- "${vDestination}/models" "${vDestination}/cache" || return 1
}

fMain() {
  if [[ "${1:-}" == '--help' || "${1:-}" == '-h' ]]; then
    fUsage
    return 0
  fi
  fParseArguments "$@" || return 1
  fLocateSources || return 1
  fCheckDependencies || return 1
  fPrepareDestination || return 1
  fPrepareWorkDirectories || return 1
  fBuild || return 1
  fLoadLibraryCache || return 1
  fCreateBundle || return 1
  fVerifyBundle || return 1
  fInstallBundle || return 1
  printf '\nBundle ready: %s (%s Vulkan drivers)\n' "${vDestination}" "${vDriverCount}"
  printf 'Start it with:\n  %s/%s --model %s/models/model.gguf\n' "${vDestination}" "${cBinaryName}" "${vDestination}"
  printf 'Then open http://127.0.0.1:8080/ (API under /api/, documentation at /api/doc/).\n'
  printf 'The folder can be moved or copied elsewhere without rebuilding.\n'
  printf 'Run this script again after updating the GPU drivers.\n'
}

if ! fMain "$@" < /dev/null; then
  printf 'Local build failed.\n' >&2
  exit 1
fi
