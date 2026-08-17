# racer-platform

RACER/Swarm-LIO 的公共环境定义，供 `swarmlio-single` 与 `swarmlio_multi` 引用同一个 platform commit 或容器 digest。

当前状态是 `incomplete_local_baseline`：主机、ROS/Gazebo、上游源码 commit、CPU-only Docker 构建和主要依赖已有实机证据，但 PX4、Swarm-LIO、Livox 仿真插件和 RACER 都存在尚未封装的本地改动；apt snapshot、Python artifact hashes、LKH 来源、源码 patch 发布和完整 GitHub 协作闭环仍未完成。因此现在不能声称环境已完全可重建。

入口：

- [ENVIRONMENT_SYNC.md](ENVIRONMENT_SYNC.md)：版本选择、原生/Docker 路径和 single/multi 同步合同；
- [platform.lock.yaml](platform.lock.yaml)：当前实机身份与缺口；
- [repos.repos](repos.repos)：已确认的上游 Git commit；
- [repos.le8e.repos](repos.le8e.repos)：LE8E 必需源码清单，不导入队友已有的 PX4/Gazebo 基础环境；
- [scripts/verify_infrastructure_compatibility.sh](scripts/verify_infrastructure_compatibility.sh)：只读检查队友已有 PX4/Gazebo 是否可作为基础环境复用；
- [environment/OPEN_ITEMS.md](environment/OPEN_ITEMS.md)：阻止发布可重建基线的开放项；
- [environment/PLATFORM_MANIFEST.template.yaml](environment/PLATFORM_MANIFEST.template.yaml)：每次构建/实验应保存的环境 manifest。

所有有副作用的脚本默认只检查。安装需显式使用 `--apply` 并设置 `RACER_PLATFORM_ALLOW_INSTALL=yes`；源码导入需显式设置 `RACER_PLATFORM_ALLOW_DOWNLOAD=yes`。验证脚本不启动 ROS、Gazebo、PX4 或实验。
