#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
check_file() { if [[ -f "$1" ]]; then echo "OK file $1"; else echo "MISSING file $1"; fail=1; fi; }
check_dir() { if [[ -d "$1" ]]; then echo "OK dir  $1"; else echo "MISSING dir  $1"; fail=1; fi; }
check_hash() {
  local expected="$1" path="$2" actual
  check_file "$path" || return
  actual="$(sha256sum "$path" | awk '{print $1}')"
  if [[ "$actual" == "$expected" ]]; then echo "OK sha  $path"; else echo "HASH MISMATCH $path expected=$expected actual=$actual"; fail=1; fi
}

check_file /home/houslakers/auto_tune_racer/swarmlio-single/run_e2l_le8e_primary_8x600.sh
check_file /home/houslakers/auto_tune_racer/swarmlio-single/run_e2l_le8i_overnight_randomized_3arm_8x600.sh
check_file /home/houslakers/auto_tune_racer/swarmlio-single/run_e2l_le8c_pure_postplan_gate.sh
check_file /home/houslakers/auto_tune_racer/swarmlio-single/run_e2l_le4_memory_600.sh
check_file /home/houslakers/auto_tune_racer/swarmlio-single/topology_t1s4r_runner.py
check_file /home/houslakers/auto_tune_racer/master.py
check_dir /home/houslakers/PX4-Autopilot
check_dir /home/houslakers/swarm_ws/src/Swarm-LIO2
check_dir /home/houslakers/swarm_ws/src/livox_laser_simulation
check_dir /home/houslakers/racer_ws/src/RACER
check_file /home/houslakers/control_code/swarm_pc_translator.py
check_file /home/houslakers/control_code/swarm_bridge.launch
check_file /home/houslakers/auto_tune_racer/px4_gazebo_registered_mapper.py
check_file /home/houslakers/auto_tune_racer/scorer.py
check_file /home/houslakers/auto_tune_racer/racer_example.world
check_file /home/houslakers/racer_ws/src/RACER/swarm_exploration/exploration_manager/launch/single_drone_planner.xml
check_file /home/houslakers/racer_ws/src/RACER/swarm_exploration/exploration_manager/launch/single_drone_exploration.xml

check_hash 4219924e4b12cba5fb2c80908b4396e52a2e1d22e61b079e94db920810c28260 /home/houslakers/auto_tune_racer/swarmlio-single/run_e2l_le8e_primary_8x600.sh
check_hash 3cf179994adb1b1c957615cc3e88ea4f2d938e7e4ed3f38ec080b3404c7d25a4 /home/houslakers/auto_tune_racer/swarmlio-single/run_e2l_le8i_overnight_randomized_3arm_8x600.sh
check_hash f51b2a6e3a202bb01bf20233cc13ab32944ffaed7e3c46f0bd9d08bf191eb4ce /home/houslakers/auto_tune_racer/master.py
check_hash 832840e344212d451c246a468c8906679f68675cac35dcb31b61a4d2b0636cb7 /home/houslakers/control_code/swarm_pc_translator.py
check_hash fcd1662b8102692d9a7572a4767b494e3e151429d56e80c82cc9d4692e921d3b /home/houslakers/control_code/swarm_bridge.launch
check_hash 53bb8a94af925affc2093d25e601d5a203065b4a1671f004a0e553d033c523fb /home/houslakers/auto_tune_racer/racer_example.world
check_hash f4d0f517198673db73cd5855fc4ce799b0b24dae5259c7d6b6875d51ff47e9f1 /home/houslakers/racer_ws/src/RACER/swarm_exploration/exploration_manager/launch/single_drone_planner.xml
check_hash 609cf7f34de0779307c1e6a76c9dc730594854fa71ce3c7048ff6c055193dda0 /home/houslakers/racer_ws/src/RACER/swarm_exploration/exploration_manager/launch/single_drone_exploration.xml

for repo in /home/houslakers/PX4-Autopilot /home/houslakers/swarm_ws/src/Swarm-LIO2 /home/houslakers/swarm_ws/src/livox_laser_simulation /home/houslakers/racer_ws/src/RACER; do
  echo "--- git $repo"
  git -C "$repo" log -1 --format='commit %H %s' || fail=1
  git -C "$repo" status --short | sed -n '1,12p'
done

if (( fail )); then echo "SINGLE_UAV_PATH_VERIFY_FAIL"; exit 1; fi
echo "SINGLE_UAV_PATH_VERIFY_PASS (read-only; no ROS/Gazebo/PX4 started)"
