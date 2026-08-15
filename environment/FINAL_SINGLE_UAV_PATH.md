# 单机最终仿真路径冻结记录

本文件把 `swarmlio-single/project_state.md` 和单机交接手册中确认的 LE8-E 节点基线、
以及最终 `3×8×600 s` 证据矩阵映射为
`racer-platform` 的环境合同。它只记录路径、入口、源码身份和哈希，不复制
PX4、Swarm-LIO、RACER 的源码、`devel/build`、地图或实验结果。

## 最终采用配置

进入多机时，每架无人机默认采用 LE8-E 节点级基线：

```text
obstacles_inflation=0.35
progress_guard=false
global_trajectory_guard=false
global_trajectory_reject_unknown=false
```

其余 LE8-E 运行时值、边界和 LSE 参数见 `platform.lock.yaml`。

LE8-E 在最终三臂矩阵中每臂运行 8 次，每次 600 s；该矩阵共 `3×8×600 s`，
seed 为 `20260812`。LE8-E 是多机迁移的节点基线，另外 LE8-G/LE8-I 只是对照臂。

## 基线入口

```text
run_e2l_le8e_primary_8x600.sh
  -> run_e2l_le8c_pure_postplan_gate.sh
  -> run_e2l_le4_memory_600.sh
  -> topology_t1s4r_runner.py
  -> /home/houslakers/auto_tune_racer/master.py
```

终局证据矩阵另由：

```text
run_e2l_le8i_overnight_randomized_3arm_8x600.sh
```

执行。它负责随机交错三臂取证，不代表多机应采用 LE8-I。

最终总控实际启动的运行链为：

```text
ROS Noetic
  -> PX4 SITL + Gazebo Classic
  -> control_code/swarm_pc_translator.py
  -> Swarm-LIO multi_uav_swarm_lio.launch
  -> px4_gazebo_registered_mapper.py (RACER_GT_MAPPER=1)
  -> control_code/swarm_bridge.launch
  -> RACER swarm_exploration.launch
  -> scorer.py
```

## 运行时源码位置

- PX4：`/home/houslakers/PX4-Autopilot`
- Swarm-LIO：`/home/houslakers/swarm_ws/src/Swarm-LIO2`
- Livox 仿真：`/home/houslakers/swarm_ws/src/livox_laser_simulation`
- RACER：`/home/houslakers/racer_ws/src/RACER`
- 控制桥接：`/home/houslakers/control_code`
- 总控、GT mapper、评分器：`/home/houslakers/auto_tune_racer`
- 仿真世界：`/home/houslakers/auto_tune_racer/racer_example.world`

## 使用方式

在宿主机上先执行：

```bash
cd /home/houslakers/auto_tune_racer/swarmlio-single
/home/houslakers/auto_tune_racer/racer-platform/scripts/verify_single_uav_path.sh
```

该校验只检查 LE8-E 基线入口、终局矩阵入口、工作区、关键 launch 文件、Git commit/dirty 状态和已冻结
哈希，不启动实验。当前源码树是带本地修改的工作树，不能把上游 commit 单独
当作最终可复现版本；后续应把各工作树的最小 patch 作为独立 artifact 发布。
