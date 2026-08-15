#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${RACER_PLATFORM_SOURCE_ROOT:-${ROOT}/sources}"
MODE=check
WITH_SUBMODULES=false

usage() {
  echo "Usage: $0 [--check|--apply] [--with-submodules]"
  echo "Source root: RACER_PLATFORM_SOURCE_ROOT (default: ${ROOT}/sources)"
}

while (($#)); do
  case "$1" in
    --check) MODE=check ;;
    --apply) MODE=apply ;;
    --with-submodules) WITH_SUBMODULES=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

LOCK="${ROOT}/repos.repos"
[[ -r "${LOCK}" ]] || { echo "ERROR: missing ${LOCK}" >&2; exit 3; }
if grep -Eq 'TODO|(^|[^[:alnum:]_])(main|master|latest)([^[:alnum:]_]|$)' "${LOCK}"; then
  echo "ERROR: repos.repos contains an unresolved or floating version" >&2
  exit 4
fi

command -v vcs >/dev/null 2>&1 || {
  echo "ERROR: vcstool is not installed; its package/version is still an OPEN_ITEM" >&2
  exit 5
}
vcs validate "${LOCK}"

if [[ "${MODE}" == check ]]; then
  if [[ -d "${SOURCE_ROOT}" ]]; then
    vcs status "${SOURCE_ROOT}" || true
  else
    echo "SOURCE_ROOT_ABSENT: ${SOURCE_ROOT}"
  fi
  echo "SOURCE_LOCK_VALID"
  exit 0
fi

[[ "${RACER_PLATFORM_ALLOW_DOWNLOAD:-no}" == yes ]] || {
  echo "ERROR: set RACER_PLATFORM_ALLOW_DOWNLOAD=yes to authorize network source import" >&2
  exit 6
}
mkdir -p "${SOURCE_ROOT}"
vcs import "${SOURCE_ROOT}" < "${LOCK}"

if ${WITH_SUBMODULES}; then
  for repo in PX4-Autopilot RACER Swarm-LIO2; do
    [[ -d "${SOURCE_ROOT}/${repo}/.git" ]] || continue
    git -C "${SOURCE_ROOT}/${repo}" submodule update --init --recursive
  done
fi

vcs status "${SOURCE_ROOT}"
echo "SOURCES_IMPORTED: ${SOURCE_ROOT}"

