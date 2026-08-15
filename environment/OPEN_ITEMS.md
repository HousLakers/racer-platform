# Environment open items

截至 2026-08-15，本目录是经过实机审计的准备骨架，不是完整可重建发行版。以下项目解决前，`platform.lock.yaml` 必须保持 `incomplete_local_baseline`。

## 已确认事实

- 宿主机：Ubuntu 20.04.6 LTS (focal)，x86_64，kernel `5.19.17-051917-generic`。
- ROS：Noetic，`ros-base` apt `1.5.0-1focal.20250521.010531`，`ros_comm` apt `1.17.4-1focal.20250520.000923`。
- Gazebo Classic：`11.15.1`，apt `11.15.1-1~focal`。
- MAVROS：ROS apt 二进制安装，版本 `1.20.1`；不是当前本地源码构建。
- 当前规划器源码位于 `/home/houslakers/racer_ws/src/RACER`；`racer_ws` 根不是 Git 仓库，RACER 子目录才是。
- 当前感知源码位于 `/home/houslakers/swarm_ws/src/Swarm-LIO2`；活动的 `livox_ros_driver` 是该仓库内的 `livox_ros_driver_mars`，package version `2.0.0`。
- 独立的 `/home/houslakers/livox_ws/src/livox_ros_driver2` 为 clean Git checkout、tag `1.2.6`，但不是上述 Swarm-LIO workspace 的活动驱动。
- RACER 交接手册列出的六个关键文件 SHA256 与当前文件完全一致。
- Docker client `26.1.3` 已安装，X11 `DISPLAY=:1` 且 `/tmp/.X11-unix/X0` 存在。

## 阻断可重建发布的未确认项

1. `TODO_PLATFORM_GIT_COMMIT`：`racer-platform` 当前不是有效 Git 仓库；single、multi 下的 `.git` 目录也不构成有效 repository metadata。需决定仓库边界、remote、branch 和首个公共基线 commit。
2. `TODO_PX4_PATCH_ARTIFACT`：PX4 base commit 已知，但 superproject 有 3 个 tracked 改动；Gazebo Classic submodule 在 commit `f835e077...` 上另有 `iris.sdf.jinja`、`empty.world` 两项 tracked 改动，patch SHA256 已记录。需导出两层 patch、递归 submodule status 和适用顺序。
3. `TODO_SWARM_LIO_PATCH_ARTIFACT`：Swarm-LIO2 有 212 个 tracked 变化和 92 个 untracked 文件；其中很多是 vendored Livox SDK mode/build 噪声，但 `swarm_lio/src`、消息、launch 和脚本也有实质修改。需剔除日志/build 产物后形成最小 patch 和资产 manifest。
4. `TODO_LIVOX_SIM_PATCH_ARTIFACT`：Livox 仿真插件有 5 个 tracked 改动及 1 个 untracked xacro，需形成 patch 并说明模型/传感器时序语义。
5. `TODO_RACER_PATCH_ARTIFACT`：RACER 有 15 个 tracked 改动和 86 个 untracked 文件。需从备份、复制文件、地图和 ODT 中分离真正的源码/launch patch；不能把整个脏工作树直接上传。
6. `TODO_LKH_SOURCE_ORIGIN`：确认 LKH 3.0.6 tarball 的原始 URL、许可、原始归档 SHA256 和构建方式。当前仅确认本机可执行文件 SHA256。
7. `TODO_APT_SNAPSHOT_OR_ARCHIVE`：记录 Ubuntu、ROS、OSRF apt source/key 和可长期取回的 snapshot；仅有 `package=version` 不保证未来仓库仍保留对应包。
8. `TODO_PYTHON_WHEELHOUSE_OR_HASH_LOCK`：为 Python requirements 生成带 hash 的锁或受控 wheelhouse；当前只锁版本。
9. `TODO_DOCKER_BASE_DIGEST`、输出 image tag/digest：将 `ros:noetic-ros-base-focal` 替换为不可变 digest，并在构建后记录 SBOM/镜像 digest。
10. GPU：`nvidia-smi` 当前不可用；未安装 `nvidia-container-toolkit`/`nvidia-container-runtime`。需由用户确认是否确实需要 CUDA/GPU local sensing，并提供目标 GPU、驱动与 CUDA 兼容矩阵。
11. Docker 权限：当前用户不属于 `docker` group，无法访问 `/var/run/docker.sock`；Docker Compose 插件也未安装。图形 socket 存在不等于 GUI 已在容器内验证。
12. vcstool：当前 `vcs` 命令不存在。需批准并锁定其 apt 或 Python 包版本后，`import_sources.sh --apply` 才可使用。
13. PX4 的准确 build target、SITL model、Gazebo Classic 启动入口和子模块初始化合同尚未由现有证据确认；`build_workspace.sh` 因而拒绝猜测 PX4 build 命令。
14. 用户指定的 `/home/houslakers/auto_tune_racer/New_report/单机复现与AI交接手册.md` 不存在。本次只把交接包 `D_evidence/` 中的同名副本作为补充证据；需确认权威路径/版本。
15. 本机同时存在 `/usr/local` NLopt 2.7.1 和 ROS overlay 的 `nlopt.pc` 2.1.21；RACER `bspline_opt/CMakeLists.txt` 已确认硬编码 `/usr/local/include` 与 `/usr/local/lib/libnlopt.so`，但仍需记录 NLopt 2.7.1 的构建选项。GTSAM `/usr/local` 为 4.2.0，对应 clean source tag 4.2/commit 已记录，但构建选项尚未记录。

## 原生路径仍缺什么

- ROS/Ubuntu/OSRF apt repository 与 key 的固定快照；
- vcstool 固定版本；
- RACER、Swarm-LIO、PX4、Livox simulation 的可应用 patch 包及 hash；
- LKH 归档来源，及 nlopt/LKH 的验证过构建与安装前缀；
- GTSAM 4.2.0 与 NLopt 的编译选项、安装前缀和 CMake/pkg-config 解析顺序；
- 两个 catkin workspace 的最终 source layout、overlay 顺序和验证过的 build 命令；
- PX4 build target；
- 地图、模型、GT mapper、bridge/scorer 等非上游资产的外部存储 manifest。

## Docker 路径仍缺什么

- base image digest、apt snapshot、Compose v2、Docker daemon 权限；
- 若需 GPU：宿主 NVIDIA 驱动、container toolkit、CUDA 兼容版本和 compose GPU smoke；
- X11 授权策略（不要把永久 `xhost +` 写入脚本）；
- source patch/外部资产的只读输入和 image/output digest；
- 镜像 SBOM、漏洞扫描与发布仓库命名。

## Docker 不能封装的内容

- 宿主 kernel、GPU 驱动、IOMMU/设备节点与硬件本身；
- X11/Wayland server、显示授权和桌面会话；
- 主机网络、UDP/multicast、防火墙、时钟同步与实时调度；
- 真实 Livox/PX4/串口/USB 权限及 udev 规则；
- 商业/研究许可、密钥和凭据；
- 大地图、点云、bag、完整日志和实验 runroot。它们应进入受控外部存储，只在 Git 中保存 hash、manifest 和引用。
