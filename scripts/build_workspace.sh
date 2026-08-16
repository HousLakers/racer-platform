#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${RACER_PLATFORM_SOURCE_ROOT:-${ROOT}/sources}"
WORK_ROOT="${RACER_PLATFORM_WORK_ROOT:-${ROOT}/workspace}"
MODE=check
COMPONENT=all
blocked=0

usage() {
  echo "Usage: $0 [--check|--apply] [--component swarm|racer|px4|all]"
}

while (($#)); do
  case "$1" in
    --check) MODE=check ;;
    --apply) MODE=apply ;;
    --component) shift; COMPONENT="${1:-}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done
[[ "${COMPONENT}" =~ ^(swarm|racer|px4|all)$ ]] || { echo "ERROR: invalid component" >&2; exit 3; }

[[ -f /opt/ros/noetic/setup.bash ]] || { echo "ERROR: ROS Noetic setup is missing" >&2; exit 4; }
source /opt/ros/noetic/setup.bash

case "${COMPONENT}" in
  swarm) required=(Swarm-LIO2) ;;
  racer) required=(RACER) ;;
  px4) required=(PX4-Autopilot) ;;
  all) required=(RACER Swarm-LIO2) ;;
esac
missing_sources=0
for repo in "${required[@]}"; do
  if [[ ! -d "${SOURCE_ROOT}/${repo}/.git" ]]; then
    echo "MISSING_SOURCE: ${SOURCE_ROOT}/${repo}"
    missing_sources=1
  fi
done

if grep -q 'patch_artifact: TODO' "${ROOT}/platform.lock.yaml"; then
  echo "BLOCKED: required local patch artifacts are not yet captured" >&2
  blocked=1
  [[ "${MODE}" == check ]] || exit 5
fi

if [[ "${COMPONENT}" == px4 ]]; then
  echo "ERROR: the verified PX4 build target/command is not yet recorded in OPEN_ITEMS.md" >&2
  exit 6
fi

if [[ "${COMPONENT}" == racer || "${COMPONENT}" == all ]]; then
  [[ -x /usr/local/bin/LKH ]] || { echo "ERROR: verified LKH 3.0.6 is missing from /usr/local/bin/LKH" >&2; missing_sources=1; }
  [[ -r /usr/local/lib/libnlopt.so ]] || { echo "ERROR: verified NLopt 2.7.1 is missing from /usr/local/lib" >&2; missing_sources=1; }
fi

if [[ "${MODE}" == check ]]; then
  ((missing_sources == 0 && blocked == 0)) || exit 10
  echo "WORKSPACE_CHECK_COMPLETE"
  exit 0
fi
((missing_sources == 0)) || exit 7

command -v catkin_make >/dev/null 2>&1 || { echo "ERROR: catkin_make is unavailable" >&2; exit 8; }

link_source() {
  local target=$1 source=$2
  mkdir -p "$(dirname "${target}")"
  if [[ -e "${target}" && ! -L "${target}" ]]; then
    echo "ERROR: refusing to replace non-symlink ${target}" >&2
    exit 9
  fi
  ln -sfn "${source}" "${target}"
}

if [[ "${COMPONENT}" == swarm || "${COMPONENT}" == all ]]; then
  link_source "${WORK_ROOT}/swarm_ws/src/Swarm-LIO2" "${SOURCE_ROOT}/Swarm-LIO2"
  [[ -d "${SOURCE_ROOT}/FAST_LIO" ]] && link_source "${WORK_ROOT}/swarm_ws/src/FAST_LIO" "${SOURCE_ROOT}/FAST_LIO"
  [[ -d "${SOURCE_ROOT}/livox_laser_simulation" ]] && link_source "${WORK_ROOT}/swarm_ws/src/livox_laser_simulation" "${SOURCE_ROOT}/livox_laser_simulation"
  [[ -d "${SOURCE_ROOT}/gazebo_ros_link_attacher" ]] && link_source "${WORK_ROOT}/swarm_ws/src/gazebo_ros_link_attacher" "${SOURCE_ROOT}/gazebo_ros_link_attacher"
  (cd "${WORK_ROOT}/swarm_ws" && catkin_make -DCMAKE_BUILD_TYPE=Release \
    -DLIVOX_SDK_ROOT="${SOURCE_ROOT}/Livox-SDK")
fi

if [[ "${COMPONENT}" == racer || "${COMPONENT}" == all ]]; then
  link_source "${WORK_ROOT}/racer_ws/src/RACER" "${SOURCE_ROOT}/RACER"
  (cd "${WORK_ROOT}/racer_ws" && catkin_make -DCMAKE_BUILD_TYPE=Release)
fi

echo "WORKSPACE_BUILD_COMPLETE"
