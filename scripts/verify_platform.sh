#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${RACER_PLATFORM_SOURCE_ROOT:-${ROOT}/sources}"
USE_OBSERVED=false
[[ "${1:-}" == --observed-host ]] && USE_OBSERVED=true

failures=0
warnings=0
pass() { printf 'PASS: %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL: %s\n' "$*"; failures=$((failures + 1)); }

check_equal() {
  local label=$1 expected=$2 actual=$3
  [[ "${actual}" == "${expected}" ]] && pass "${label}=${actual}" || fail "${label} expected=${expected} actual=${actual:-missing}"
}

os_version="$(. /etc/os-release; printf '%s' "${VERSION_ID}")"
check_equal host_os 20.04 "${os_version}"
check_equal kernel 5.19.17-051917-generic "$(uname -r)"

[[ -f /opt/ros/noetic/setup.bash ]] || fail "ROS Noetic setup missing"
if [[ -f /opt/ros/noetic/setup.bash ]]; then
  source /opt/ros/noetic/setup.bash
  check_equal ros_distribution noetic "$(rosversion -d 2>/dev/null || true)"
  check_equal mavros 1.20.1 "$(rosversion mavros 2>/dev/null || true)"
fi
check_equal ros_base_apt 1.5.0-1focal.20250521.010531 "$(dpkg-query -W -f='${Version}' ros-noetic-ros-base 2>/dev/null || true)"
check_equal ros_comm_apt 1.17.4-1focal.20250520.000923 "$(dpkg-query -W -f='${Version}' ros-noetic-ros-comm 2>/dev/null || true)"
check_equal gazebo 11.15.1 "$(gazebo --version 2>/dev/null | sed -n 's/.*version //p' | head -1)"
check_equal python 3.8.10 "$(python3 -c 'import platform; print(platform.python_version())')"
check_equal pip 25.0.1 "$(python3 -m pip --version 2>/dev/null | awk '{print $2}')"

while IFS= read -r package_spec; do
  [[ -n "${package_spec}" ]] || continue
  package_name="${package_spec%%=*}"
  expected_version="${package_spec#*=}"
  installed_version="$(dpkg-query -W -f='${Version}' "${package_name}" 2>/dev/null || true)"
  [[ "${installed_version}" == "${expected_version}" ]] || fail "apt ${package_name} expected=${expected_version} actual=${installed_version:-missing}"
done < <(sed -E '/^[[:space:]]*(#|$)/d' "${ROOT}/environment/apt-packages.txt")

tmp_dir="$(mktemp -d /tmp/racer-platform-verify.XXXXXX)"
trap 'rm -rf "${tmp_dir}"' EXIT
sed -E '/^[[:space:]]*(#|$)/d' "${ROOT}/environment/python-requirements.txt" | sort > "${tmp_dir}/expected-python.txt"
python3 -m pip freeze --user 2>/dev/null | sort > "${tmp_dir}/actual-python.txt"
if cmp -s "${tmp_dir}/expected-python.txt" "${tmp_dir}/actual-python.txt"; then
  pass "user Python lock matches"
else
  warn "user Python lock differs; inspect diff below"
  diff -u "${tmp_dir}/expected-python.txt" "${tmp_dir}/actual-python.txt" || true
fi

if ${USE_OBSERVED}; then
  declare -A repo_paths=(
    [PX4-Autopilot]=/home/houslakers/PX4-Autopilot
    [RACER]=/home/houslakers/racer_ws/src/RACER
    [Swarm-LIO2]=/home/houslakers/swarm_ws/src/Swarm-LIO2
    [livox_ros_driver2]=/home/houslakers/livox_ws/src/livox_ros_driver2
    [livox_laser_simulation]=/home/houslakers/swarm_ws/src/livox_laser_simulation
  )
else
  declare -A repo_paths=(
    [PX4-Autopilot]="${SOURCE_ROOT}/PX4-Autopilot"
    [RACER]="${SOURCE_ROOT}/RACER"
    [Swarm-LIO2]="${SOURCE_ROOT}/Swarm-LIO2"
    [livox_ros_driver2]="${SOURCE_ROOT}/livox_ros_driver2"
    [livox_laser_simulation]="${SOURCE_ROOT}/livox_laser_simulation"
  )
fi
declare -A repo_commits=(
  [PX4-Autopilot]=13e74de617e97e748d60af11a66b23b7f02e4551
  [RACER]=049c332e3634ef72d8beb155b4c13dc91ca52916
  [Swarm-LIO2]=a5f751a797bb92baa3104cdd384a312d3c8e7744
  [livox_ros_driver2]=13eb05e4e6dd7a765b934d0c5fd6236676a57b49
  [livox_laser_simulation]=1cce1073633a062b92e30243a4c2920e45551bb5
)
for repo in "${!repo_paths[@]}"; do
  path="${repo_paths[${repo}]}"
  if git -C "${path}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    check_equal "${repo}_commit" "${repo_commits[${repo}]}" "$(git -C "${path}" rev-parse HEAD)"
    if [[ -n "$(git -C "${path}" status --porcelain=v1)" ]]; then
      warn "${repo} has local changes"
    else
      pass "${repo} clean"
    fi
  else
    fail "${repo} is missing or is not a Git repository: ${path}"
  fi
done

command -v docker >/dev/null 2>&1 && pass "Docker client $(docker --version)" || warn "Docker client unavailable"
docker compose version >/dev/null 2>&1 && pass "Docker Compose plugin available" || warn "Docker Compose plugin unavailable"
docker info >/dev/null 2>&1 && pass "Docker daemon accessible" || warn "Docker daemon inaccessible to current user"
[[ -n "${DISPLAY:-}" && -d /tmp/.X11-unix ]] && pass "X11 display/socket present" || warn "X11 display/socket incomplete"
command -v nvidia-container-runtime >/dev/null 2>&1 && pass "NVIDIA container runtime present" || warn "NVIDIA container runtime unavailable"

todo_count="$(rg -n 'TODO_[A-Z0-9_]+' "${ROOT}/platform.lock.yaml" "${ROOT}/environment/OPEN_ITEMS.md" 2>/dev/null | wc -l || true)"
if ((todo_count > 0)); then
  warn "platform has ${todo_count} unresolved TODO references"
fi

printf 'SUMMARY: failures=%d warnings=%d\n' "${failures}" "${warnings}"
((failures == 0)) || exit 1
((todo_count == 0)) || exit 10
echo "PLATFORM_MATCH"
