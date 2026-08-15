#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE=check
WITH_PYTHON=false
incomplete=0

usage() {
  echo "Usage: $0 [--check|--apply] [--with-python]"
  echo "  --check         validate locks and report installed-package drift (default)"
  echo "  --apply         run apt-get; requires RACER_PLATFORM_ALLOW_INSTALL=yes"
  echo "  --with-python   also install the pinned user-site Python requirements"
}

while (($#)); do
  case "$1" in
    --check) MODE=check ;;
    --apply) MODE=apply ;;
    --with-python) WITH_PYTHON=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

APT_LOCK="${ROOT}/environment/apt-packages.txt"
PYTHON_LOCK="${ROOT}/environment/python-requirements.txt"
[[ -r "${APT_LOCK}" && -r "${PYTHON_LOCK}" ]] || {
  echo "ERROR: dependency manifests are missing" >&2
  exit 3
}

if grep -Eq 'TODO|(^|[^[:alnum:]_])latest([^[:alnum:]_]|$)' "${ROOT}/platform.lock.yaml"; then
  echo "BLOCKED: platform.lock.yaml is incomplete; see environment/OPEN_ITEMS.md" >&2
  incomplete=1
  [[ "${MODE}" == check ]] || exit 4
fi

if [[ "$(. /etc/os-release; printf '%s' "${VERSION_ID}")" != 20.04 ]]; then
  echo "ERROR: this lock targets Ubuntu 20.04" >&2
  exit 5
fi

mapfile -t apt_packages < <(sed -E '/^[[:space:]]*(#|$)/d' "${APT_LOCK}")
for package_spec in "${apt_packages[@]}"; do
  [[ "${package_spec}" =~ ^[a-z0-9][a-z0-9+.-]*=[^[:space:]]+$ ]] || {
    echo "ERROR: apt entry is not exactly pinned: ${package_spec}" >&2
    exit 6
  }
done

if [[ "${MODE}" == check ]]; then
  mismatch=0
  for package_spec in "${apt_packages[@]}"; do
    package_name="${package_spec%%=*}"
    expected_version="${package_spec#*=}"
    installed_version="$(dpkg-query -W -f='${Version}' "${package_name}" 2>/dev/null || true)"
    if [[ "${installed_version}" != "${expected_version}" ]]; then
      printf 'MISMATCH apt %s expected=%s installed=%s\n' \
        "${package_name}" "${expected_version}" "${installed_version:-missing}"
      mismatch=1
    fi
  done
  ${WITH_PYTHON} && python3 -m pip check
  ((mismatch == 0)) && echo "APT_LOCK_MATCH"
  ((mismatch == 0)) || exit 1
  ((incomplete == 0)) || exit 10
  exit 0
fi

[[ "${RACER_PLATFORM_ALLOW_INSTALL:-no}" == yes ]] || {
  echo "ERROR: set RACER_PLATFORM_ALLOW_INSTALL=yes to authorize package installation" >&2
  exit 7
}

if [[ "${EUID}" -eq 0 ]]; then
  sudo_cmd=()
else
  command -v sudo >/dev/null 2>&1 || { echo "ERROR: sudo is required" >&2; exit 8; }
  sudo_cmd=(sudo)
fi

"${sudo_cmd[@]}" apt-get update
"${sudo_cmd[@]}" apt-get install -y --no-install-recommends "${apt_packages[@]}"

if ${WITH_PYTHON}; then
  python3 -m pip install --user --requirement "${PYTHON_LOCK}"
fi

echo "NATIVE_DEPENDENCIES_INSTALLED"
