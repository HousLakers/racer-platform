# racer-platform

RACER/Swarm-LIO 的公共环境定义，供 `swarmlio-single` 与 `swarmlio_multi` 引用同一个 platform commit 或容器 digest。

当前状态是“源码重建与编译已验证、完整 PX4-Gazebo 运行链仍需宿主机联调”：CPU-only Docker、LE8E 专用源码导入、submodule、Livox SDK、Swarm-LIO 和 RACER 编译均已有本地证据；完整 PX4 SITL + Gazebo + 传感器 + 总控实验尚未由本仓库独立完成。

入口：

- [ENVIRONMENT_SYNC.md](ENVIRONMENT_SYNC.md)：版本选择、原生/Docker 路径和 single/multi 同步合同；
- [RUN_LE8E.md](RUN_LE8E.md)：从队友已有 PX4/Gazebo 到 LE8E 仿真启动的实际操作手册；
- [platform.lock.yaml](platform.lock.yaml)：当前实机身份与缺口；
- [repos.repos](repos.repos)：已确认的上游 Git commit；
- [repos.le8e.repos](repos.le8e.repos)：LE8E 必需源码清单，不导入队友已有的 PX4/Gazebo 基础环境；
- [scripts/verify_infrastructure_compatibility.sh](scripts/verify_infrastructure_compatibility.sh)：只读检查队友已有 PX4/Gazebo 是否可作为基础环境复用；
- [scripts/apply_le8e_patches.sh](scripts/apply_le8e_patches.sh)：在固定 commit 的 clean 源码上检查/应用 LE8E patch；
- [environment/OPEN_ITEMS.md](environment/OPEN_ITEMS.md)：阻止发布可重建基线的开放项；
- [environment/PLATFORM_MANIFEST.template.yaml](environment/PLATFORM_MANIFEST.template.yaml)：每次构建/实验应保存的环境 manifest。

所有有副作用的脚本默认只检查。安装需显式使用 `--apply` 并设置 `RACER_PLATFORM_ALLOW_INSTALL=yes`；源码导入需显式设置 `RACER_PLATFORM_ALLOW_DOWNLOAD=yes`。验证脚本不启动 ROS、Gazebo、PX4 或实验。
