# LE8-E baseline candidate patch manifest

状态：`candidate_for_review`。这些 patch 从当前已按 LE8-E 启动链核对过的
本机工作树提取，尚未宣称为最终公共发行版。

## 基准 commit

| component | repository | base commit |
|---|---|---|
| PX4 superproject | `/home/houslakers/PX4-Autopilot` | `13e74de617e97e748d60af11a66b23b7f02e4551` |
| PX4 Gazebo Classic submodule | `Tools/simulation/gazebo-classic/sitl_gazebo-classic` | `f835e077d06eaf09a57d5152fcfb85244b53b77a` |
| Swarm-LIO2 | `/home/houslakers/swarm_ws/src/Swarm-LIO2` | `a5f751a797bb92baa3104cdd384a312d3c8e7744` |
| Livox simulation | `/home/houslakers/swarm_ws/src/livox_laser_simulation` | `1cce1073633a062b92e30243a4c2920e45551bb5` |
| RACER | `/home/houslakers/racer_ws/src/RACER` | `049c332e3634ef72d8beb155b4c13dc91ca52916` |

## 应用顺序

1. 在对应 base commit checkout PX4 superproject；应用 `px4-superproject.patch`。
2. 初始化并 checkout PX4 Gazebo Classic submodule；在 submodule 根目录应用
   `px4-gazebo-classic.patch`。
3. 在 Swarm-LIO2 根目录应用 `swarm-lio-source.patch`。
4. 在 Swarm-LIO2 根目录应用 `livox-driver-no-autodownload.patch`。
5. 在 Livox simulation 根目录应用 `livox-simulation.patch`。
6. 在 RACER 根目录应用 `racer-le8e-source.patch`。
7. 独立导入并构建固定 commit 的 `Livox-SDK`，再配置 `LIVOX_SDK_ROOT`。
8. 重新生成源码 manifest 和 patch hash，先做静态检查，再由 sol 审核后构建。

## 纳入内容

- PX4 multi-UAV SITL launch、posix launch、iris contact sensor 和 empty world 改动；
- Swarm-LIO 当前多机源码、multi-UAV launch、消息定义和 `px4_bridge.py`；
- Livox ROS driver 的 CMake 防自动下载修复；
- Livox Mid360 仿真插件、CMake、ODE/point plugin 和 xacro；
- RACER LE8E 运行所需规划器、探索管理器、前沿、轨迹、单机 launch 和
  `swarm_exploration_multi.launch`。

## 明确排除

- Swarm-LIO/Livox SDK 的 build、CMake cache、二进制、sample、doc image 和大范围
  vendored SDK 清理变更；
- Swarm-LIO `swarm_lio/Log`、`cmake-build-debug` 和运行产物；
- RACER 的 `.orig`、`.pre_*`、`.t1*backup`、复制目录、ODT、PCD/PLY 和旧 launch；
- 所有 ROS `build/`、`devel/`、日志、结果和实验 runroot。

排除项不会被删除，仍保留在原始工作树中供人工追溯。若后续构建证明某个被排除
文件是运行必需项，应单独提出新的 patch，不把整个目录重新打包。

## 文件哈希

见同目录 `SHA256SUMS`。重新生成或修改任何 patch 后，必须同步更新该文件和
本 manifest 的审计日期。
