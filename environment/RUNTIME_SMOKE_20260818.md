# LE8E 本地运行冒烟证据

## 结论

2026-08-18 已在本机使用当前 LE8E 单机运行链路完成一次 30 秒仿真冒烟测试，完整节点链路启动、运行、评分并清理成功。

本次验证使用宿主机已有的 PX4、Gazebo、ROS 工作区、控制桥接和实验总控；它验证的是“当前 LE8E 参数链路能运行”，不是在空白机器上独立重建 PX4/Gazebo 的证明。

## 参数基线

本次运行对应 `platform.lock.yaml` 中冻结的 LE8-E 节点基线：

```text
obstacles_inflation=0.35
progress_guard_enabled=false
global_trajectory_guard_enabled=false
global_trajectory_reject_unknown=false
RACER_GT_MAPPER=1
registration_source=gt
```

其余 LE8-E LSE 参数继续以 `platform.lock.yaml` 和
`environment/FINAL_SINGLE_UAV_PATH.md` 为准。

## 实际链路证据

```text
PX4 SITL + Gazebo
  -> swarm_pc_translator.py
  -> Swarm-LIO multi_uav_swarm_lio.launch
  -> px4_gazebo_registered_mapper.py
  -> swarm_bridge.launch
  -> RACER swarm_exploration.launch
  -> scorer.py
```

观测到的关键事实：

- Livox 点云成功从 `PointCloud` 转为 `PointCloud2`；
- GT mapper 注册扫描持续增长，`dropped=0`；
- bridge 进入 `OFFBOARD armed=True` 并发送运动指令；
- RACER 持续执行 `Replan`；
- 生成轨迹、地图、指标和评分文件；
- `crashed=false`、`collision_count=0`，测试结束后无残留仿真进程。

## 结果摘要

```text
sim_elapsed_seconds=30.124
wall_elapsed_seconds=47.064
ATE RMSE=0.1237 m
path_len=24.2925 m
map_coverage=0.1368
score.total=0.7379
score.safety=0.7782
score.efficiency=0.6439
```

原始结果保存在实验仓库本地，不提交到公共环境仓库：

```text
/home/houslakers/auto_tune_racer/results/0818_0250_it00/
```

本证据只记录可审计摘要；完整日志、地图和轨迹继续遵守仓库的大文件边界。

