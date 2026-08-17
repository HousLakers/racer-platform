#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${RACER_PLATFORM_SOURCE_ROOT:-${ROOT}/sources}"
MODE=check
SKIP_PX4=false
PATCH_ROOT="${ROOT}/patches/20260815-le8e-baseline"

usage() {
  cat <<EOF
Usage: $0 [--check|--apply] [--skip-px4]
Source root: ${SOURCE_ROOT}
Default mode only runs git apply --check.
Applying patches requires RACER_PLATFORM_ALLOW_PATCH_APPLY=yes.
--skip-px4 reuses the teammate's existing PX4/Gazebo after a separate
compatibility preflight; it does not apply PX4 patches.
EOF
}

while (($#)); do
  case "$1" in
    --check) MODE=check ;;
    --apply) MODE=apply ;;
    --skip-px4) SKIP_PX4=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

fail() { echo "ERROR: $*" >&2; exit 1; }
require_repo() {
  local name=$1 expected=$2 path=$3
  [[ -d "${path}" ]] || fail "missing ${name}: ${path}"
  git -C "${path}" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "not a Git repository: ${name} (${path})"
  local actual
  actual="$(git -C "${path}" rev-parse HEAD)"
  [[ "${actual}" == "${expected}" ]] \
    || fail "${name} commit mismatch: expected=${expected} actual=${actual}"
  [[ -z "$(git -C "${path}" status --short --ignore-submodules=none)" ]] \
    || fail "${name} is dirty: ${path}"
}
apply_one() {
  local name=$1 repo=$2 patch=$3
  [[ -f "${patch}" ]] || fail "missing patch: ${patch}"
  if git -C "${repo}" apply --check "${patch}"; then
    echo "PATCH_READY: ${name}"
  elif git -C "${repo}" apply --reverse --check "${patch}"; then
    echo "PATCH_ALREADY_APPLIED: ${name}"
    return 0
  else
    fail "patch does not apply cleanly: ${name}"
  fi
  if [[ "${MODE}" == apply ]]; then
    git -C "${repo}" apply "${patch}"
    echo "PATCH_APPLIED: ${name}"
  fi
}

SWARM_ROOT="${SOURCE_ROOT}/Swarm-LIO2"
LIVOX_SIM_ROOT="${SOURCE_ROOT}/livox_laser_simulation"
RACER_ROOT="${SOURCE_ROOT}/RACER"

require_repo Swarm-LIO2 a5f751a797bb92baa3104cdd384a312d3c8e7744 "${SWARM_ROOT}"
require_repo livox_laser_simulation 1cce1073633a062b92e30243a4c2920e45551bb5 "${LIVOX_SIM_ROOT}"
require_repo RACER 049c332e3634ef72d8beb155b4c13dc91ca52916 "${RACER_ROOT}"

if ${SKIP_PX4}; then
  echo "WARNING: reusing teammate PX4/Gazebo; run verify_infrastructure_compatibility.sh first"
else
  PX4_ROOT="${SOURCE_ROOT}/PX4-Autopilot"
  PX4_GAZEBO_ROOT="${PX4_ROOT}/Tools/simulation/gazebo-classic/sitl_gazebo-classic"
  require_repo PX4-Autopilot 13e74de617e97e748d60af11a66b23b7f02e4551 "${PX4_ROOT}"
  require_repo PX4-Gazebo-submodule f835e077d06eaf09a57d5152fcfb85244b53b77a "${PX4_GAZEBO_ROOT}"
fi

if [[ "${MODE}" == apply ]]; then
  [[ "${RACER_PLATFORM_ALLOW_PATCH_APPLY:-no}" == yes ]] \
    || fail "set RACER_PLATFORM_ALLOW_PATCH_APPLY=yes to authorize patch application"
fi

if ! ${SKIP_PX4}; then
  apply_one "PX4 superproject" "${PX4_ROOT}" "${PATCH_ROOT}/px4-superproject.patch"
  apply_one "PX4 Gazebo Classic" "${PX4_GAZEBO_ROOT}" "${PATCH_ROOT}/px4-gazebo-classic.patch"
fi
apply_one "Swarm-LIO2" "${SWARM_ROOT}" "${PATCH_ROOT}/swarm-lio-source.patch"
apply_one "Livox driver build contract" "${SWARM_ROOT}" "${PATCH_ROOT}/livox-driver-no-autodownload.patch"
apply_one "Livox simulation" "${LIVOX_SIM_ROOT}" "${PATCH_ROOT}/livox-simulation.patch"
apply_one "RACER LE8E" "${RACER_ROOT}" "${PATCH_ROOT}/racer-le8e-source.patch"

echo "LE8E_PATCH_CHECK_PASS: mode=${MODE} source_root=${SOURCE_ROOT}"
