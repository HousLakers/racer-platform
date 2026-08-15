#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-${ROOT}/environment/current-platform-report.txt}"
case "$(realpath -m "${OUT}")" in
  "${ROOT}/environment/"*) ;;
  *) echo "ERROR: report output must stay under ${ROOT}/environment" >&2; exit 2 ;;
esac
mkdir -p "$(dirname "${OUT}")"
tmp_report="$(mktemp "${ROOT}/environment/.platform-report.XXXXXX")"
trap 'rm -f "${tmp_report}"' EXIT

repos=(
  /home/houslakers/PX4-Autopilot
  /home/houslakers/livox_ws/src/livox_ros_driver2
  /home/houslakers/swarm_ws/src/Swarm-LIO2
  /home/houslakers/swarm_ws/src/livox_laser_simulation
  /home/houslakers/racer_ws/src/RACER
  /home/houslakers/racer_ws/src/RACER_DEPS/nlopt
)

{
  echo "# Generated platform report"
  date --iso-8601=seconds || date
  echo "kernel: $(uname -a)"
  sed -n '1,40p' /etc/os-release
  echo "--- commands ---"
  for command_name in git docker roscore gazebo make gcc python3 pip3 vcs; do
    printf '%s: ' "${command_name}"
    command -v "${command_name}" 2>/dev/null || echo missing
  done
  echo "--- core versions ---"
  if [[ -f /opt/ros/noetic/setup.bash ]]; then
    source /opt/ros/noetic/setup.bash
    rosversion -d 2>&1 || true
    rosversion mavros 2>&1 || true
  fi
  gazebo --version 2>&1 || true
  python3 --version 2>&1 || true
  docker --version 2>&1 || true
  docker compose version 2>&1 || true
  nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>&1 || true
  echo "DISPLAY=${DISPLAY:-unset}"
  [[ -d /tmp/.X11-unix ]] && echo "x11_socket_dir=present" || echo "x11_socket_dir=missing"
  echo "--- selected apt packages ---"
  dpkg-query -W -f='${Package}=${Version}\n' \
    gazebo11 ros-noetic-ros-base ros-noetic-ros-comm \
    ros-noetic-mavros ros-noetic-mavros-extras ros-noetic-gazebo-ros-pkgs \
    python3 python3-pip gcc g++ cmake make 2>&1 || true
  echo "--- user Python packages ---"
  python3 -m pip freeze --user 2>&1 || true
  echo "--- git repositories ---"
  for repo in "${repos[@]}"; do
    echo "repo: ${repo}"
    if git -C "${repo}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      printf 'toplevel: '; git -C "${repo}" rev-parse --show-toplevel
      printf 'commit: '; git -C "${repo}" rev-parse HEAD
      printf 'branch: '; git -C "${repo}" branch --show-current
      printf 'origin: '; git -C "${repo}" remote get-url origin 2>/dev/null || echo missing
      printf 'tracked_changes: '; git -C "${repo}" status --porcelain=v1 -uno | wc -l
      printf 'untracked_files: '; git -C "${repo}" ls-files --others --exclude-standard | wc -l
      printf 'worktree_patch_sha256: '; git -C "${repo}" diff --binary | sha256sum | cut -d' ' -f1
    else
      echo "status: not_a_git_repository"
    fi
  done
} > "${tmp_report}"

mv "${tmp_report}" "${OUT}"
trap - EXIT
echo "Wrote ${OUT}"
