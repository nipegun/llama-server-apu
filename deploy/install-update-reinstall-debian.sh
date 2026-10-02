#!/bin/bash

set -euo pipefail

cRepository='https://github.com/nipegun/llama-server-apu'
cArchiveUrl="${cRepository}/archive/refs/heads/main.tar.gz"
cSourceRoot='/opt/llama-server-apu-source'
vWorkDirectory=''
vSourceLocked=0

fCleanup() {
  local vStatus=$?
  if [[ -n "${vWorkDirectory}" && "${vWorkDirectory}" == "${cSourceRoot}/_/temp/bootstrap."* ]]; then
    rm -rf -- "${vWorkDirectory}" || true
  fi
  if (( vSourceLocked )); then
    flock -u 9 || true
  fi
  return "${vStatus}"
}

trap fCleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

fBootstrapDependencies() {
  local vCommand
  local vMissing=0
  for vCommand in curl tar gzip rsync flock; do
    if ! command -v "${vCommand}" >/dev/null 2>&1; then
      vMissing=1
    fi
  done
  if (( vMissing )) || [[ ! -s /etc/ssl/certs/ca-certificates.crt ]]; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update || return 1
    apt-get install -y --no-install-recommends \
      -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
      ca-certificates curl tar gzip rsync util-linux || return 1
  fi
}

fDownloadSources() {
  # This directory is managed by the installer; build/cache files stay in _/temp/.
  local vDirectory
  for vDirectory in "${cSourceRoot}" "${cSourceRoot}/_" "${cSourceRoot}/_/temp"; do
    if [[ -L "${vDirectory}" ]]; then
      printf 'Refusing a symbolic link at %s.\n' "${vDirectory}" >&2
      return 1
    fi
    mkdir -p -- "${vDirectory}" || return 1
    if [[ ! -O "${vDirectory}" ]]; then
      printf 'The source directory must be owned by root: %s\n' "${vDirectory}" >&2
      return 1
    fi
    chmod 0700 "${vDirectory}" || return 1
  done
  exec 9>"${cSourceRoot}/_/temp/install.lock" || return 1
  flock -n 9 || { printf 'Another installation is using %s.\n' "${cSourceRoot}" >&2; return 1; }
  vSourceLocked=1
  vWorkDirectory="$(mktemp -d "${cSourceRoot}/_/temp/bootstrap.XXXXXXXX")" || return 1
  printf 'Downloading the main branch from %s...\n' "${cRepository}"
  curl --fail --silent --show-error --location --retry 3 \
    --connect-timeout 30 --max-time 600 --proto '=https' --proto-redir '=https' \
    --output "${vWorkDirectory}/source.tar.gz" "${cArchiveUrl}" || return 1
  mkdir -p "${vWorkDirectory}/source" || return 1
  tar -xzf "${vWorkDirectory}/source.tar.gz" --strip-components=1 \
    --no-same-owner --no-same-permissions -C "${vWorkDirectory}/source" || return 1
  local vRequired
  for vRequired in build/CMakeLists.txt backend/CMakeLists.txt frontend/package.json deploy/install-common.sh deploy/start-web.py; do
    if [[ ! -s "${vWorkDirectory}/source/${vRequired}" ]]; then
      printf 'The downloaded source archive is incomplete: %s\n' "${vRequired}" >&2
      return 1
    fi
  done
  # Synchronize only after the complete snapshot has downloaded and extracted.
  # Exclusions also protect these files from --delete-delay on repeat runs.
  rsync -a --checksum --delete-delay --no-owner --no-group \
    --exclude='/_/' --exclude='/.git/' --exclude='/.agents/' \
    --exclude='/.codex/' --exclude='/.aws/' --exclude='node_modules/' \
    --exclude='/Rules/' --exclude='/AGENTS.md' \
    --exclude='/CLAUDE.md' --exclude='/RulesForThisProjectOnly.md' \
    "${vWorkDirectory}/source/" "${cSourceRoot}/" || return 1
}

fMain() {
  if [[ "${1:-}" == '--help' || "${1:-}" == '-h' ]]; then
    printf '%s\n' \
      'Install/update/reinstall llama-server-apu on Debian as root.' \
      'Supports curl URL | bash and curl URL | bash -s -- OPTIONS.' \
      '--model PATH: initial GGUF model; later runs reuse the installed model.' \
      '--domain HOST, --prefix PATH, --without-ui/--with-ui: saved installation settings.' \
      '--cert PATH --cert-key PATH: replace certificates; --jobs N: build parallelism.' \
      '--build-only: build a self-contained bundle in ~/IA/Apps/llama-server-apu as a normal user.' \
      'Build options: --destination PATH, --jobs N, --without-ui/--with-ui.' \
      'Build dependencies must already be installed; temporary files stay in /tmp.' \
      'With no initial model, an attached terminal is prompted through /dev/tty.'
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
  # A streamed script has no BASH_SOURCE[0]; a downloaded standalone file may
  # have one without the rest of the project. Both cases use the remote snapshot.
  local vEntry="${BASH_SOURCE[0]:-}"
  local vDirectory=''
  if [[ -n "${vEntry}" && -f "${vEntry}" ]]; then
    vDirectory="$(cd -- "$(dirname -- "${vEntry}")" && pwd -P)" || return 1
  fi
  # Select compilation before touching deployment sources, settings or logs.
  if (( vBuildOnly )); then
    if [[ -n "${vDirectory}" && -f "${vDirectory}/../build/build-local.sh" ]]; then
      bash "${vDirectory}/../build/build-local.sh" "${aBuildArguments[@]}" < /dev/null || return 1
    else
      curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
        https://raw.githubusercontent.com/nipegun/llama-server-apu/refs/heads/main/build/build-local.sh \
        | bash -s -- "${aBuildArguments[@]}" || return 1
    fi
    return 0
  fi
  (( EUID == 0 )) || { printf 'Run this installer as root.\n' >&2; return 1; }
  if [[ -n "${vDirectory}" && -f "${vDirectory}/install-common.sh" && -f "${vDirectory}/../build/CMakeLists.txt" && -f "${vDirectory}/../backend/CMakeLists.txt" ]]; then
    bash "${vDirectory}/install-common.sh" debian "$@" < /dev/null || return 1
    return 0
  fi
  command -v apt-get >/dev/null 2>&1 || { printf 'This installer requires Debian and apt-get.\n' >&2; return 1; }
  umask 077
  touch /root/webapp-install.log /root/webapp-credentials.txt || return 1
  chmod 0600 /root/webapp-install.log /root/webapp-credentials.txt || return 1
  exec > >(tee -a /root/webapp-install.log) 2>&1
  fBootstrapDependencies || return 1
  fDownloadSources || return 1
  # FD 9 is inherited so the shared installer retains the same source lock.
  APU_INSTALL_LOG_OPEN=1 bash "${cSourceRoot}/deploy/install-common.sh" debian "$@" < /dev/null || return 1
}

if ! fMain "$@" < /dev/null; then
  printf 'Build or deployment failed.\n' >&2
  exit 1
fi
