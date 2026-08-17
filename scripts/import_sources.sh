#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${RACER_PLATFORM_SOURCE_ROOT:-${ROOT}/sources}"
MODE=check
WITH_SUBMODULES=false
PROFILE=full

usage() {
  echo "Usage: $0 [--check|--apply] [--profile full|le8e] [--with-submodules]"
  echo "Source root: RACER_PLATFORM_SOURCE_ROOT (default: ${ROOT}/sources)"
  echo "Profile full: all locked repositories, including PX4"
  echo "Profile le8e: only LE8E project sources; does not import PX4/Gazebo"
}

while (($#)); do
  case "$1" in
    --check) MODE=check ;;
    --apply) MODE=apply ;;
    --profile)
      (($# >= 2)) || { echo "ERROR: --profile requires full or le8e" >&2; exit 2; }
      PROFILE="$2"
      shift
      ;;
    --with-submodules) WITH_SUBMODULES=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "${PROFILE}" in
  full) LOCK="${ROOT}/repos.repos" ;;
  le8e) LOCK="${ROOT}/repos.le8e.repos" ;;
  *) echo "ERROR: unsupported profile: ${PROFILE}" >&2; exit 2 ;;
esac
[[ -r "${LOCK}" ]] || { echo "ERROR: missing ${LOCK}" >&2; exit 3; }
if grep -Eq 'TODO|(^|[^[:alnum:]_])(main|master|latest)([^[:alnum:]_]|$)' "${LOCK}"; then
  echo "ERROR: repos.repos contains an unresolved or floating version" >&2
  exit 4
fi

command -v vcs >/dev/null 2>&1 || {
  echo "ERROR: vcstool is not installed; its package/version is still an OPEN_ITEM" >&2
  exit 5
}
# The Ubuntu focal vcstool 0.3.0 package has a validate-time bug for some
# immutable Git commits (version_type may remain unset). Validate the manifest
# structurally here; the apply path still verifies the exact commit after clone.
python3 - "${LOCK}" <<'PY'
import re
import sys
import yaml

path = sys.argv[1]
with open(path, encoding="utf-8") as stream:
    document = yaml.safe_load(stream)

repositories = document.get("repositories") if isinstance(document, dict) else None
if not isinstance(repositories, dict) or not repositories:
    raise SystemExit("ERROR: repositories manifest must contain a non-empty repositories map")

for name, spec in repositories.items():
    if not isinstance(spec, dict) or spec.get("type") != "git":
        raise SystemExit(f"ERROR: {name}: only git repositories are supported")
    url = spec.get("url")
    version = str(spec.get("version", ""))
    if not isinstance(url, str) or not url.startswith(("https://", "git@")):
        raise SystemExit(f"ERROR: {name}: invalid git URL")
    if not re.fullmatch(r"[0-9a-fA-F]{40}", version):
        raise SystemExit(f"ERROR: {name}: version must be a 40-character commit")

print(f"REPOSITORY_MANIFEST_VALID: {path} ({len(repositories)} repositories)")
PY

check_existing_repositories() {
  [[ -d "${SOURCE_ROOT}" ]] || return 0

  while IFS=$'\t' read -r repo expected_commit; do
    [[ -n "${repo}" ]] || continue
    local path="${SOURCE_ROOT}/${repo}"
    [[ -e "${path}" ]] || continue

    if [[ ! -d "${path}/.git" ]]; then
      echo "ERROR: existing source path is not a Git repository: ${path}" >&2
      return 1
    fi

    local actual_commit
    actual_commit="$(git -C "${path}" rev-parse HEAD)"
    if [[ "${actual_commit}" != "${expected_commit}" ]]; then
      echo "ERROR: existing repository has unexpected commit: ${repo}" >&2
      echo "  expected: ${expected_commit}" >&2
      echo "  actual:   ${actual_commit}" >&2
      return 1
    fi

    if [[ -n "$(git -C "${path}" status --short --ignore-submodules=none)" ]]; then
      echo "ERROR: existing repository has local modifications: ${path}" >&2
      return 1
    fi

    echo "EXISTING_REPOSITORY_MATCH: ${repo}@${expected_commit}"
  done < <(awk '
    /^[[:space:]]{2}[^[:space:]#][^:]*:[[:space:]]*$/ {
      repo=$0
      sub(/^[[:space:]]+/, "", repo)
      sub(/:[[:space:]]*$/, "", repo)
      next
    }
    /^[[:space:]]{4}version:[[:space:]]*/ {
      version=$0
      sub(/^[[:space:]]*version:[[:space:]]*/, "", version)
      print repo "\t" version
    }
  ' "${LOCK}")
}

check_existing_repositories

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
vcs import --skip-existing "${SOURCE_ROOT}" < "${LOCK}"

if ${WITH_SUBMODULES}; then
  for repo in PX4-Autopilot RACER Swarm-LIO2; do
    [[ -d "${SOURCE_ROOT}/${repo}/.git" ]] || continue
    git -C "${SOURCE_ROOT}/${repo}" submodule update --init --recursive
  done
fi

vcs status "${SOURCE_ROOT}"
echo "SOURCES_IMPORTED: profile=${PROFILE} root=${SOURCE_ROOT}"
