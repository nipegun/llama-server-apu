#!/bin/bash

set -euo pipefail

fCleanup() {
  :
}

trap fCleanup EXIT

fMain() {
  local vDirectory
  vDirectory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)" || return 1
  bash "${vDirectory}/install-common.sh" alpine "$@" || return 1
}

if ! fMain "$@"; then
  printf 'Installation failed.\n' >&2
  exit 1
fi
