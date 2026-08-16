# Native dependency and catkin build audit — 2026-08-16

本次只进行固定依赖编译和 catkin 构建，没有启动 ROS master、Gazebo、PX4、bridge、
scorer 或任何实验 runner。

## Livox SDK

- repository: `https://github.com/Livox-SDK/Livox-SDK.git`
- commit: `9306596a2bf15c1343bc023b497465ed0a32909d`
- target: `livox_sdk_static`
- result: `Built target livox_sdk_static`
- output: `build/sdk_core/liblivox_sdk_static.a`

## Swarm-LIO

```bash
source /opt/ros/noetic/setup.bash
cd /home/houslakers/swarm_ws
catkin_make --pkg swarm_lio -DCMAKE_BUILD_TYPE=Release \
  -DLIVOX_SDK_ROOT=/home/houslakers/swarm_ws/src/Swarm-LIO2/livox_ros_driver_mars/Livox-SDK
```

结果：`Built target swarm_lio`，通过。

本次构建使用固定 Livox SDK，未触发网络 clone。`livox_ros_driver_mars` 的
CMake 防自动下载 patch 已纳入候选 patch manifest。

## 与此前 RACER 构建合并的结论

- Livox SDK：通过；
- Swarm-LIO：通过；
- RACER `exploration_node`：通过；
- 以上均为原生编译验证，不代表已经启动或验证仿真运行时。

构建日志保存在本机 `/tmp`，不纳入 Git；源码工作树中的 build/devel 产物也不纳入
公共仓库。
