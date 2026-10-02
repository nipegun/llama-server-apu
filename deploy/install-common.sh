#!/bin/bash

set -euo pipefail

cService='llama-server-apu'
cHome="/opt/${cService}"
cProjectRoot="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
cInstallSettings="${cHome}/config/install.conf"
vDomain='localhost'
vModel=''
vJobs=''
vBuildUi='ON'
vPrefix='/usr/local'
vCertificate=''
vCertificateKey=''
vBuildDirectory="${cProjectRoot}/_/temp/build"
vInstallationLocked=0

fCleanup() {
  local vStatus=$?
  if (( vInstallationLocked )); then
    # Explicit unlock also releases the lock if a service inherited FD 9.
    flock -u 9 || true
  fi
  return "${vStatus}"
}

trap fCleanup EXIT

fFail() {
  printf 'Error: %s\n' "$*" >&2
  return 1
}

fUsage() {
  printf '%s\n' \
    'Install, update or reinstall llama-server-apu as root.' \
    'Options:' \
    '  --model PATH        GGUF model; defaults to the already installed model.' \
    '  --domain HOST       HTTPS hostname (saved value, initially localhost).' \
    '  --cert PATH         Existing PEM certificate (requires --cert-key).' \
    '  --cert-key PATH     Existing PEM private key.' \
    '  --jobs N            Parallel build jobs.' \
    '  --build-only        Build a self-contained bundle as a normal user.' \
    '  --destination PATH  Bundle directory with --build-only (default: ~/IA/Apps/llama-server-apu).' \
    '  --without-ui        Build the API without the chat interface.' \
    '  --with-ui           Enable the chat interface again.' \
    '  --prefix PATH       Binary prefix (saved value, initially /usr/local).' \
    '  --help              Display this help.' \
    'HTTP starts at 11080 and HTTPS at 11443; occupied ports are skipped at startup.' \
    'Both inference and the dedicated web server run as llama-server-apu.'
}

fLockInstallation() {
  local pDistribution="$1"
  if ! command -v flock >/dev/null 2>&1; then
    case "${pDistribution}" in
      debian)
        apt-get update || return 1
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
          -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold util-linux || return 1
        ;;
      alpine) apk add --no-cache util-linux || return 1 ;;
      *) fFail 'Supported distributions: debian, alpine.'; return 1 ;;
    esac
  fi
  mkdir -p "${cProjectRoot}/_/temp" || return 1
  local vLockPath="${cProjectRoot}/_/temp/install.lock"
  local vInheritedLock=''
  if [[ -e "/proc/${BASHPID}/fd/9" ]]; then
    vInheritedLock="$(readlink "/proc/${BASHPID}/fd/9")" || return 1
  fi
  if [[ "${vInheritedLock}" != "${vLockPath}" ]]; then
    exec 9>"${vLockPath}" || return 1
  fi
  flock -n 9 || { fFail 'Another installation is using this source directory.'; return 1; }
  vInstallationLocked=1
}

fLoadInstallationSettings() {
  if [[ -f "${cInstallSettings}" ]]; then
    local vName=''
    local vValue=''
    # Parse data only. Never source/eval a saved settings file as root.
    while IFS='=' read -r vName vValue || [[ -n "${vName}" ]]; do
      case "${vName}" in
        domain) vDomain="${vValue}" ;;
        prefix) vPrefix="${vValue}" ;;
        buildUi) vBuildUi="${vValue}" ;;
      esac
    done < "${cInstallSettings}"
  fi
  if [[ -f "${cHome}/models/model.gguf" ]]; then
    vModel="${cHome}/models/model.gguf"
  fi
}

fRequestInitialModel() {
  local vTerminal
  if ! { exec {vTerminal}<> /dev/tty; } 2>/dev/null; then
    fFail 'The first installation needs --model PATH. Use curl URL | bash -s -- --model /path/model.gguf.'
    return 1
  fi
  printf 'Path to the GGUF model for the first installation: ' >&"${vTerminal}"
  local vStatus=0
  IFS= read -r vModel <&"${vTerminal}" || vStatus=$?
  exec {vTerminal}>&-
  (( vStatus == 0 )) || { fFail 'No model path was received.'; return 1; }
}

fSaveInstallationSettings() {
  printf 'domain=%s\nprefix=%s\nbuildUi=%s\n' \
    "${vDomain}" "${vPrefix}" "${vBuildUi}" > "${cInstallSettings}" || return 1
  chown root:root "${cInstallSettings}" || return 1
  chmod 0600 "${cInstallSettings}" || return 1
}

fParseArguments() {
  while (($#)); do
    case "$1" in
      --model|--domain|--cert|--cert-key|--jobs|--prefix)
        (($# >= 2)) || { fFail "Missing value for $1"; return 1; }
        case "$1" in
          --model) vModel="$2" ;;
          --domain) vDomain="$2" ;;
          --cert) vCertificate="$2" ;;
          --cert-key) vCertificateKey="$2" ;;
          --jobs) vJobs="$2" ;;
          --prefix) vPrefix="$2" ;;
        esac
        shift 2
        ;;
      --without-ui) vBuildUi='OFF'; shift ;;
      --with-ui) vBuildUi='ON'; shift ;;
      *) fFail "Unknown option: $1"; return 1 ;;
    esac
  done
  [[ "${vDomain}" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]] || { fFail 'Invalid hostname.'; return 1; }
  [[ "${vPrefix}" =~ ^/[A-Za-z0-9_./-]+$ && "${vPrefix}" != '/' ]] || { fFail 'Invalid installation prefix.'; return 1; }
  [[ -z "${vJobs}" || "${vJobs}" =~ ^[1-9][0-9]*$ ]] || { fFail 'Jobs must be a positive integer.'; return 1; }
  [[ -n "${vJobs}" ]] || vJobs="$(getconf _NPROCESSORS_ONLN)" || return 1
  [[ "${vBuildUi}" == 'ON' || "${vBuildUi}" == 'OFF' ]] || { fFail 'Saved buildUi must be ON or OFF.'; return 1; }
  if [[ -z "${vModel}" ]]; then
    fRequestInitialModel || return 1
  fi
  [[ -n "${vModel}" && -f "${vModel}" && -r "${vModel}" ]] || { fFail '--model must name a readable GGUF file.'; return 1; }
  if [[ -n "${vCertificate}" || -n "${vCertificateKey}" ]]; then
    [[ -r "${vCertificate}" && -r "${vCertificateKey}" ]] || { fFail 'Both certificate files must be readable.'; return 1; }
  fi
}

fInstallDependencies() {
  local pDistribution="$1"
  case "${pDistribution}" in
    debian)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update || return 1
      apt-get install -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
        build-essential cmake ninja-build pkg-config libssl-dev \
        libcurl4-openssl-dev libvulkan-dev glslc spirv-headers mesa-vulkan-drivers vulkan-tools \
        nodejs npm rsync ca-certificates apache2-bin openssl python3 || return 1
      ;;
    alpine)
      apk add --no-cache bash build-base cmake ninja pkgconf openssl-dev curl-dev \
        vulkan-loader-dev shaderc spirv-headers mesa-vulkan-ati mesa-vulkan-intel vulkan-tools linux-headers \
        nodejs npm rsync ca-certificates apache2 apache2-ssl apache2-proxy openssl shadow python3 || return 1
      ;;
    *) fFail 'Supported distributions: debian, alpine.'; return 1 ;;
  esac
}

fBuild() {
  local vFilesystem
  vFilesystem="$(stat -f -c '%T' "${cProjectRoot}")" || return 1
  case "${vFilesystem}" in
    fuse|fuseblk|nfs|nfs4|cifs|smb2)
      fFail 'Copy the complete project to a local filesystem before building. Build files stay in _/temp/.'
      return 1
      ;;
  esac
  mkdir -p "${vBuildDirectory}" "${cProjectRoot}/_/temp/npm-cache" || return 1
  local -a aCmakeArguments=(
    -S "${cProjectRoot}/build"
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
  export npm_config_cache="${cProjectRoot}/_/temp/npm-cache"
  cmake "${aCmakeArguments[@]}" || return 1
  cmake --build "${vBuildDirectory}" --target llama-server-apu --parallel "${vJobs}" || return 1
  install -D -m 0755 "${vBuildDirectory}/bin/llama-server-apu" "${vPrefix}/bin/llama-server-apu" || return 1
}

fPrepareAccount() {
  if ! getent group "${cService}" >/dev/null; then
    groupadd --system "${cService}" || return 1
  fi
  if ! id "${cService}" >/dev/null 2>&1; then
    useradd --system --gid "${cService}" --home-dir "${cHome}" --shell /usr/sbin/nologin "${cService}" || return 1
  fi
  install -d -m 0750 -o "${cService}" -g "${cService}" "${cHome}" "${cHome}/models" "${cHome}/cache" || return 1
  install -d -m 0750 -o root -g "${cService}" "${cHome}/config" || return 1
  install -d -m 0750 -o root -g "${cService}" "${cHome}/certificates" || return 1
  install -d -m 0750 -o "${cService}" -g "${cService}" "${cHome}/web" || return 1
  local vGroup
  for vGroup in render video; do
    if getent group "${vGroup}" >/dev/null; then
      usermod -a -G "${vGroup}" "${cService}" || return 1
    fi
  done
  local vSourceModel
  vSourceModel="$(realpath -- "${vModel}")" || return 1
  if [[ "${vSourceModel}" != "${cHome}/models/model.gguf" ]]; then
    rsync -t --chmod=F640 --chown="${cService}:${cService}" -- "${vSourceModel}" "${cHome}/models/model.gguf" || return 1
  fi
  chown "${cService}:${cService}" "${cHome}/models/model.gguf" || return 1
  chmod 0640 "${cHome}/models/model.gguf" || return 1
  if [[ ! -s "${cHome}/config/api-key.txt" ]]; then
    openssl rand -hex 32 > "${cHome}/config/api-key.txt" || return 1
  fi
  chown root:"${cService}" "${cHome}/config/api-key.txt" || return 1
  chmod 0640 "${cHome}/config/api-key.txt" || return 1
  local vApiKey
  vApiKey="$(cat "${cHome}/config/api-key.txt")" || return 1
  if ! grep -q '^llama-server-apu API key:' /root/webapp-credentials.txt; then
    printf 'llama-server-apu system account: locked; no login password\nllama-server-apu API key: %s\n' "${vApiKey}" >> /root/webapp-credentials.txt || return 1
  fi
}

fPrepareCertificate() {
  if [[ -n "${vCertificate}" ]]; then
    if [[ ! "${vCertificate}" -ef "${cHome}/certificates/server.crt" ]]; then
      install -m 0600 "${vCertificate}" "${cHome}/certificates/server.crt" || return 1
    fi
    if [[ ! "${vCertificateKey}" -ef "${cHome}/certificates/server.key" ]]; then
      install -m 0600 "${vCertificateKey}" "${cHome}/certificates/server.key" || return 1
    fi
  elif [[ ! -s "${cHome}/certificates/server.crt" || ! -s "${cHome}/certificates/server.key" ]]; then
    openssl req -x509 -newkey rsa:3072 -nodes -days 365 \
      -subj "/CN=${vDomain}" -addext "subjectAltName=DNS:${vDomain}" \
      -keyout "${cHome}/certificates/server.key" \
      -out "${cHome}/certificates/server.crt" || return 1
    chmod 0600 "${cHome}/certificates/server.key" "${cHome}/certificates/server.crt" || return 1
  fi
  chown root:"${cService}" "${cHome}/certificates/server.key" "${cHome}/certificates/server.crt" || return 1
  chmod 0640 "${cHome}/certificates/server.key" "${cHome}/certificates/server.crt" || return 1
}

fConfigureServices() {
  local pDistribution="$1"
  local vApacheBinary
  local vModuleDirectory
  install -d -m 0755 "/var/www/${vDomain}" || return 1
  install -d -m 0750 -o "${cService}" -g "${cService}" "/var/www/${vDomain}-logs" || return 1
  install -m 0644 "${cProjectRoot}/deploy/start-web.py" "${cHome}/config/start-web.py" || return 1
  install -m 0644 "${cProjectRoot}/deploy/apache.conf.in" "${cHome}/config/apache.conf.in" || return 1
  if [[ "${pDistribution}" == debian ]]; then
    vApacheBinary='/usr/sbin/apache2'
    vModuleDirectory='/usr/lib/apache2/modules'
    sed -e "s|@PREFIX@|${vPrefix}|g" "${cProjectRoot}/deploy/llama-server-apu.service.in" > /etc/systemd/system/llama-server-apu.service || return 1
    install -m 0644 "${cProjectRoot}/deploy/llama-server-apu-web.service.in" /etc/systemd/system/llama-server-apu-web.service || return 1
  else
    vApacheBinary='/usr/sbin/httpd'
    vModuleDirectory='/usr/lib/apache2'
    sed -e "s|@PREFIX@|${vPrefix}|g" "${cProjectRoot}/deploy/llama-server-apu.openrc.in" > /etc/init.d/llama-server-apu || return 1
    chmod 0755 /etc/init.d/llama-server-apu || return 1
    install -m 0755 "${cProjectRoot}/deploy/llama-server-apu-web.openrc.in" /etc/init.d/llama-server-apu-web || return 1
  fi
  printf '{"domain":"%s","apacheBinary":"%s","moduleDirectory":"%s"}\n' \
    "${vDomain}" "${vApacheBinary}" "${vModuleDirectory}" > "${cHome}/config/web.json" || return 1
  chown root:"${cService}" "${cHome}/config/web.json" || return 1
  chmod 0640 "${cHome}/config/web.json" || return 1
  rm -f "${cHome}/web/ports.json" || return 1
  if [[ "${pDistribution}" == debian ]]; then
    systemctl daemon-reload || return 1
    systemctl enable llama-server-apu llama-server-apu-web || return 1
    systemctl restart llama-server-apu llama-server-apu-web || return 1
  else
    rc-update add llama-server-apu default || return 1
    rc-update add llama-server-apu-web default || return 1
    rc-service llama-server-apu restart || return 1
    rc-service llama-server-apu-web restart || return 1
  fi
  python3 -B "${cHome}/config/start-web.py" --show-urls || return 1
}

fMain() {
  local pDistribution="${1:-}"
  shift || return 1
  if [[ "${1:-}" == '--help' || "${1:-}" == '-h' ]]; then
    fUsage
    return 0
  fi
  local vArgument
  local vBuildOnly=0
  local vExpectValue=0
  local -a aBuildArguments=()
  for vArgument in "$@"; do
    if (( vExpectValue )); then
      aBuildArguments+=("${vArgument}")
      vExpectValue=0
      continue
    fi
    case "${vArgument}" in
      --build-only) vBuildOnly=1 ;;
      --model|--domain|--cert|--cert-key|--jobs|--prefix|--destination)
        aBuildArguments+=("${vArgument}")
        vExpectValue=1
        ;;
      *) aBuildArguments+=("${vArgument}") ;;
    esac
  done
  if (( vBuildOnly )); then
    bash "${cProjectRoot}/build/build-local.sh" "${aBuildArguments[@]}" < /dev/null || return 1
    return 0
  fi
  (( EUID == 0 )) || { fFail 'Run this installer as root.'; return 1; }
  umask 077
  touch /root/webapp-install.log /root/webapp-credentials.txt || return 1
  chmod 0600 /root/webapp-install.log /root/webapp-credentials.txt || return 1
  if [[ "${APU_INSTALL_LOG_OPEN:-0}" != 1 ]]; then
    exec > >(tee -a /root/webapp-install.log) 2>&1
  fi
  printf '\nInstallation started: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  fLockInstallation "${pDistribution}" || return 1
  fLoadInstallationSettings || return 1
  fParseArguments "$@" || return 1
  fInstallDependencies "${pDistribution}" || return 1
  fBuild || return 1
  fPrepareAccount || return 1
  fPrepareCertificate || return 1
  fConfigureServices "${pDistribution}" || return 1
  fSaveInstallationSettings || return 1
  printf 'Installation completed. Log: /root/webapp-install.log\nCredentials: /root/webapp-credentials.txt\n'
}

if ! fMain "$@"; then
  printf 'Build or deployment failed.\n' >&2
  exit 1
fi
