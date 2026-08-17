# Environment synchronization

## 1. 选择公共环境版本

环境版本的唯一身份应是 `racer-platform` 的 Git commit。队友先 checkout 明确 commit，再读取同一 commit 下的 `platform.lock.yaml`、`repos.repos` 和依赖清单。不要用 branch 名、`latest` tag 或“我本机当前目录”作为实验身份。

当前目录已是有效 Git 仓库；推送 GitHub 后，环境版本以明确的 platform commit 发布。首个“完整可重建”基线仍需关闭 `environment/OPEN_ITEMS.md` 中的关键源码 patch、apt/Python artifact 和外部资产项。

每个 single/multi run manifest 至少记录：

```text
platform_repository
platform_commit
platform_lock_sha256
source_manifest_sha256
docker_image_digest（若使用容器）
```

single 与 multi 不复制两份环境锁；它们各自在自己的 manifest/文档中引用同一个 platform commit。环境升级先在本仓库形成新 commit，再由 single 与 multi 分别验证并更新引用。

## 2. 原生安装路径

准备阶段只检查：

```bash
cd /home/houslakers/auto_tune_racer/racer-platform
./scripts/install_native.sh --check
./scripts/import_sources.sh --check
./scripts/build_workspace.sh --check
./scripts/verify_platform.sh --observed-host
```

关闭所有 TODO 并获得人工批准后，新的机器才可按顺序执行：

```bash
RACER_PLATFORM_ALLOW_INSTALL=yes ./scripts/install_native.sh --apply --with-python
RACER_PLATFORM_ALLOW_DOWNLOAD=yes ./scripts/import_sources.sh --apply --with-submodules
./scripts/build_workspace.sh --apply --component swarm
./scripts/build_workspace.sh --apply --component racer
./scripts/verify_platform.sh
```

当前 `build_workspace.sh` 会对未封装 patch、RACER_DEPS 和 PX4 build target fail closed；这不是安装完成入口。不得为了“先跑起来”删除这些门。

推荐的可重建目录由环境变量控制：

```text
RACER_PLATFORM_SOURCE_ROOT=<platform>/sources
RACER_PLATFORM_WORK_ROOT=<platform>/workspace
```

不要把 `/home/houslakers/racer_ws/build`、`devel`、`install` 复制进公共仓库。

## 3. Docker 路径

Docker build 前先把 base image 写成 digest，并给输出镜像一个不可变版本：

```bash
export RACER_PLATFORM_BASE_IMAGE='ros:noetic-ros-base-focal@sha256:<approved>'
export RACER_PLATFORM_IMAGE='registry.example/racer-platform:<platform-commit>'
```

当前已验证的 CPU-only 路径：

```bash
docker compose -f docker/compose.yaml build racer-platform
docker image inspect "$RACER_PLATFORM_IMAGE" --format '{{.Id}}'
docker compose -f docker/compose.yaml run --rm racer-platform
```

GPU 路径只在宿主驱动与 NVIDIA container runtime 验证后启用：

```bash
docker compose -f docker/compose.yaml --profile gpu run --rm racer-platform-gpu
```

Compose 使用 host network 和 X11 socket，面向 Linux 仿真主机。显示授权由操作者按会话最小化配置，不在仓库脚本中永久放宽。

## 4. 版本记录合同

- Ubuntu：`/etc/os-release` 的版本/codename，并记录 base image digest。
- ROS：distribution 之外，还记录 `ros-base`/`ros_comm` apt 完整版本。
- Gazebo：Classic 主版本和 `gazebo11` apt 完整版本。
- PX4：上游 URL、superproject commit、递归 submodule status、local patch artifact/hash、实际 build target。
- MAVROS：若为 apt，记录 `mavros`、`mavros-extras`、`mavlink` 完整 apt 版本；若改为 source build，再记录 repository commit。
- Livox：明确区分活动的 Swarm-LIO 内嵌 `livox_ros_driver`、独立 `livox_ros_driver2`、Livox SDK 和 Gazebo simulation plugin。
- Swarm-LIO/RACER：上游 commit 与 patch artifact/hash缺一不可；dirty worktree 的 HEAD 不是完整版本身份。
- 依赖：apt direct lock + snapshot，Python version lock + hashes/wheelhouse，外部 tarball URL + SHA256。

## 5. 一致性验证

`scripts/verify_platform.sh` 只做静态/只读检查：OS、kernel、ROS/Gazebo/MAVROS、apt、用户 pip、源码 commit/dirty 状态、Docker/Compose、X11/GPU 能力。它不启动 ROS master、Gazebo、PX4 或实验。

一次环境可声明“匹配”至少要求：

1. 所有关键 TODO 已关闭；
2. platform commit 和 lock hash 一致；
3. 每个源码 repo commit、submodule 和 patch hash 一致；
4. apt/Python 验证一致；
5. Docker 模式还需 base image digest 和构建输出 image ID 一致；
6. host-only 要求（GPU/显示/网络/设备）单独通过 preflight。

## 6. GitHub、镜像与外部存储边界

GitHub 放：环境文档、Dockerfile/Compose、安装/导入/构建/验证脚本、lock、`.repos`、小型可审计 patch、manifest 模板、hash/SBOM/外部引用。

Docker 镜像放：系统/ROS/编译依赖、固定 Python artifacts、经批准构建的工作区安装层；不在镜像中放密钥或实验结果。

外部存储放：地图/PCD、bag、完整日志、点云、runroot、大型二进制/模型、受许可约束的归档和私有资产。GitHub 只保存内容 hash、大小、许可、获取位置和访问策略。

永不提交：`build/`、`devel/`、`install/`、`.ros/`、Gazebo cache、完整日志、点云、密钥、Docker credential 和未脱敏主机配置。
