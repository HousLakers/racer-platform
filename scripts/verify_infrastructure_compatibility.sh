#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PX4_ROOT="${PX4_ROOT:-${RACER_PLATFORM_SOURCE_ROOT:-${ROOT}/sources}/PX4-Autopilot}"
PX4_GAZEBO_ROOT="${PX4_GAZEBO_ROOT:-${PX4_ROOT}/Tools/simulation/gazebo-classic/sitl_gazebo-classic}"
STRICT=false
CHECK_PATCHES=false

usage() {
  cat <<EOF
Usage: $0 [--strict] [--check-patches]

Read-only compatibility check for a teammate's existing PX4/Gazebo baseline.
PX4_ROOT: ${PX4_ROOT}
PX4_GAZEBO_ROOT: ${PX4_GAZEBO_ROOT}

Default mode reports version differences as WARN and never modifies sources.
--strict treats version, dirty-worktree and submodule differences as failures.
--check-patches additionally runs git apply --check without applying patches.
EOF
}

while (($#)); do
  case "$1" in
    --strict) STRICT=true ;;
    --check-patches) CHECK_PATCHES=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

failures=0
warnings=0
pass() { printf 'PASS: %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL: %s\n' "$*"; failures=$((failures + 1)); }
diff_or_warn() {
  if ${STRICT}; then fail "$*"; else warn "$*"; fi
}
is_git_worktree() {
  git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}
check_patch_state() {
  local repo=$1 patch=$2 label=$3
  if git -C "${repo}" apply --check "${patch}"; then
    pass "${label} patch applies cleanly"
  elif git -C "${repo}" apply --reverse --check "${patch}"; then
    pass "${label} patch is already applied"
  else
    diff_or_warn "${label} patch does not apply cleanly"
  fi
}

expected_px4="$(python3 - "${ROOT}/repos.repos" <<'PY'
import sys
import yaml
with open(sys.argv[1], encoding="utf-8") as stream:
    print(yaml.safe_load(stream)["repositories"]["PX4-Autopilot"]["version"])
PY
)"

if ! is_git_worktree "${PX4_ROOT}"; then
  fail "ACTION_REQUIRED: install PX4-Autopilot before LE8E launch: ${PX4_ROOT}"
else
  actual_px4="$(git -C "${PX4_ROOT}" rev-parse HEAD)"
  if [[ "${actual_px4}" == "${expected_px4}" ]]; then
    pass "PX4 commit=${actual_px4}"
  else
    diff_or_warn "PX4 commit differs: expected=${expected_px4} actual=${actual_px4}"
  fi

  if [[ -n "$(git -C "${PX4_ROOT}" status --short --ignore-submodules=none)" ]]; then
    diff_or_warn "PX4 worktree has local changes"
  else
    pass "PX4 worktree clean"
  fi

  submodule_status="$(git -C "${PX4_ROOT}" submodule status --recursive 2>/dev/null || true)"
  if printf '%s\n' "${submodule_status}" | grep -Eq '^[+-U]'; then
    diff_or_warn "PX4 submodules are not at their recorded clean state"
  else
    pass "PX4 submodules initialized and clean"
  fi
fi

gazebo_version="$(gazebo --version 2>/dev/null | sed -n 's/.*version //p' | head -1 || true)"
if [[ -z "${gazebo_version}" ]]; then
  fail "Gazebo executable is unavailable"
elif [[ "${gazebo_version}" == "11.15.1" ]]; then
  pass "Gazebo version=${gazebo_version}"
else
  diff_or_warn "Gazebo version differs: expected=11.15.1 actual=${gazebo_version}"
fi

gazebo_apt="$(dpkg-query -W -f='${Version}' gazebo11 2>/dev/null || true)"
if [[ -z "${gazebo_apt}" ]]; then
  warn "gazebo11 APT package is not installed or not queryable"
else
  pass "gazebo11 apt=${gazebo_apt}"
fi

if ${CHECK_PATCHES}; then
  px4_patch="${ROOT}/patches/20260815-le8e-baseline/px4-superproject.patch"
  gazebo_patch="${ROOT}/patches/20260815-le8e-baseline/px4-gazebo-classic.patch"
  if is_git_worktree "${PX4_ROOT}"; then
    check_patch_state "${PX4_ROOT}" "${px4_patch}" "PX4 superproject"
  fi
  if is_git_worktree "${PX4_GAZEBO_ROOT}"; then
    check_patch_state "${PX4_GAZEBO_ROOT}" "${gazebo_patch}" "PX4 Gazebo"
  else
    fail "PX4 Gazebo submodule is missing: ${PX4_GAZEBO_ROOT}"
  fi
fi

printf 'SUMMARY: failures=%d warnings=%d strict=%s\n' "${failures}" "${warnings}" "${STRICT}"
((failures == 0)) || exit 1
${STRICT} && ((warnings == 0)) || true
if ${STRICT} && ((warnings > 0)); then exit 1; fi
echo "INFRASTRUCTURE_COMPATIBILITY_REPORTED"
