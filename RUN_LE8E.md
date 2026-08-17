# LE8E 仿真运行手册

本仓库保存公共环境、固定源码清单和 patch；PX4、Gazebo、地图、控制桥接、总控和评分器仍由宿主机项目提供。
当前已验证：Docker CPU 环境、LE8E 源码导入、Livox SDK 编译、Swarm-LIO 编译、RACER 25 个 ROS 包编译、关键 launch 图解析，以及宿主机上的 30 秒 PX4 SITL + Gazebo + LE8E 完整链路冒烟。
尚未由本仓库独立完成：在干净机器上重建 PX4/Gazebo 并完成完整 600 秒矩阵。因此新机器仍应先做短时冒烟，再做 600 秒实验。

## 一、队友已有 PX4/Gazebo 的原生路径

```bash
git clone https://github.com/HousLakers/racer-platform.git
cd racer-platform

export RACER_PLATFORM_SOURCE_ROOT="$PWD/sources"
export RACER_PLATFORM_WORK_ROOT="$PWD/workspace"
```

先检查宿主机基础环境。`PX4_ROOT` 指向队友已有的 PX4 工作区：

```bash
PX4_ROOT=/path/to/PX4-Autopilot \
  ./scripts/verify_infrastructure_compatibility.sh --check-patches
```

导入 LE8E 专用源码，不会下载或覆盖 PX4/Gazebo：

```bash
RACER_PLATFORM_ALLOW_DOWNLOAD=yes \
  ./scripts/import_sources.sh --apply --profile le8e --with-submodules
```

应用 LE8E 项目 patch。`--skip-px4` 表示复用队友现有的 PX4/Gazebo：

```bash
RACER_PLATFORM_ALLOW_PATCH_APPLY=yes \
  ./scripts/apply_le8e_patches.sh --apply --skip-px4
```

构建两个工作区：

```bash
./scripts/build_workspace.sh --apply --component swarm
./scripts/build_workspace.sh --apply --component racer
```

如果脚本因 `platform.lock.yaml` 中仍保留的开放项而 fail closed，可使用等价的人工构建命令：

```bash
source /opt/ros/noetic/setup.bash

cd "$RACER_PLATFORM_WORK_ROOT/swarm_ws"
catkin_make -DCMAKE_BUILD_TYPE=Release \
  -DLIVOX_SDK_ROOT="$RACER_PLATFORM_SOURCE_ROOT/Livox-SDK"

cd "$RACER_PLATFORM_WORK_ROOT/racer_ws"
catkin_make -DCMAKE_BUILD_TYPE=Release
```

## 二、启动前的 ROS overlay

两个 catkin 工作区不能简单依赖连续 `source`，应明确合并包路径：

```bash
source /opt/ros/noetic/setup.bash
export ROS_PACKAGE_PATH="$RACER_PLATFORM_WORK_ROOT/racer_ws/src:$RACER_PLATFORM_WORK_ROOT/swarm_ws/src:/opt/ros/noetic/share"
export CMAKE_PREFIX_PATH="$RACER_PLATFORM_WORK_ROOT/racer_ws/devel:$RACER_PLATFORM_WORK_ROOT/swarm_ws/devel:/opt/ros/noetic"
rospack profile
```

检查关键包：

```bash
rospack find swarm_lio
rospack find exploration_manager
```

检查启动图，不会真正启动仿真：

```bash
roslaunch --nodes "$RACER_PLATFORM_SOURCE_ROOT/Swarm-LIO2/swarm_lio/launch/multi_uav_swarm_lio.launch"
roslaunch --nodes "$RACER_PLATFORM_SOURCE_ROOT/RACER/swarm_exploration/exploration_manager/launch/swarm_exploration.launch"
```

## 三、启动完整 LE8E 仿真

完整链路由现有总控脚本启动，顺序为：

```text
PX4 SITL + Gazebo
  -> swarm_pc_translator.py
  -> Swarm-LIO multi_uav_swarm_lio.launch
  -> GT mapper（RACER_GT_MAPPER=1）
  -> swarm_bridge.launch
  -> RACER swarm_exploration.launch
  -> scorer.py
```

在已有总控项目目录执行：

```bash
cd /path/to/auto_tune_racer
export RACER_GT_MAPPER=1
export PYTHONUNBUFFERED=1

# 首次只跑一轮、30 秒冒烟
python3 master.py --iterations 1 --duration 30

# 确认冒烟通过后，再运行单轮 600 秒
python3 master.py --iterations 1 --duration 600
```

你当前冻结的最终证据入口是：

```bash
cd /home/houslakers/auto_tune_racer/swarmlio-single
./run_e2l_le8e_primary_8x600.sh
```

该入口属于实验仓库，不属于 `racer-platform`；它会进一步调用总控和评分流程。不要在环境尚未通过短时冒烟时直接运行完整 `3×8×600 s` 矩阵。

## 四、Docker 的边界

Docker 当前验证的是 CPU-only ROS/编译依赖环境：

```bash
docker compose -f docker/compose.yaml build racer-platform
docker compose -f docker/compose.yaml run --rm racer-platform bash
```

它不会自动拥有队友宿主机的 PX4、Gazebo 运行树、地图、X11 和实验控制目录。完整 PX4-Gazebo 仿真优先使用原生路径；若以后把这些运行时资产显式挂载进容器，再单独验证容器运行链。

## 五、出现问题时先看哪里

- PX4/Gazebo 版本或 patch：`scripts/verify_infrastructure_compatibility.sh`
- 源码 commit/submodule：`scripts/import_sources.sh --check --profile le8e`
- LE8E patch：`scripts/apply_le8e_patches.sh --check --skip-px4`
- 单机冻结路径：`environment/FINAL_SINGLE_UAV_PATH.md`
- 尚未封装的开放项：`environment/OPEN_ITEMS.md`
