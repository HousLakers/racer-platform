# Native catkin build audit — 2026-08-15

本次只执行原生 catkin 编译，没有启动 ROS master、Gazebo、PX4、bridge、scorer
或任何实验 runner。

## RACER

命令：

```bash
source /opt/ros/noetic/setup.bash
source /home/houslakers/swarm_ws/devel/setup.bash
cd /home/houslakers/racer_ws
catkin_make -DCMAKE_BUILD_TYPE=Release exploration_node
```

结果：通过。

```text
Built target exploration_node
```

这证明当前 RACER dirty 工作树在已存在的 Swarm-LIO devel overlay 下能够完成
`exploration_node` 原生编译。它还不是干净环境重建证明，因为 patch 仍是
`candidate_for_review`，且使用了现有 overlay。

## Swarm-LIO

命令：

```bash
source /opt/ros/noetic/setup.bash
cd /home/houslakers/swarm_ws
catkin_make --pkg swarm_lio -DCMAKE_BUILD_TYPE=Release
```

结果：中止，未完成。

`livox_ros_driver_mars` 的 CMake 检测不到 Livox SDK，并进入了自动 clone 分支：

```text
Coudn't find livox sdk library!
Try to pull the livox sdk source code from github
Cloning into .../livox_ros_driver_mars/Livox-SDK...
```

已立即停止该构建，未允许继续网络下载。该问题不是 LE8E RACER 编译错误，而是
Livox SDK 依赖尚未形成可重建、禁止自动下载的环境资产。

## 当前结论

- RACER：原生 catkin 目标构建通过；
- Swarm-LIO：被 Livox SDK 依赖阻断；
- Docker：尚未真实构建，因 daemon/Compose 不可用；
- 实验：尚未开始。

下一步必须固定 Livox SDK 的来源、commit/归档 hash、构建方式和安装前缀，并修改
环境构建流程使 SDK 缺失时直接失败，而不是自动 clone。完成后重新运行 Swarm-LIO
catkin build，再进行 Docker build 验证。
