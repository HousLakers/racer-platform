# Local environment preflight — 2026-08-15

本记录是上传 GitHub 前的本机环境校验，不是实验结果，也没有启动
ROS/Gazebo/PX4/DeepSeek runner。

## 原生宿主机

执行：

```bash
bash scripts/verify_platform.sh --observed-host
```

通过项目：

- Ubuntu 20.04 / kernel `5.19.17-051917-generic`
- ROS Noetic、MAVROS `1.20.1`
- Gazebo Classic `11.15.1`
- Python `3.8.10`、pip `25.0.1`
- ROS apt 版本与 `environment/apt-packages.txt` 一致
- 用户 Python lock 与本机 `pip freeze --user` 一致
- PX4、Swarm-LIO2、Livox simulation、RACER 的 HEAD 与 lock 一致

警告/发布阻断：

- PX4、Swarm-LIO2、Livox simulation、RACER 都仍有本地修改；尚未形成可发布
  的最小 patch artifact。
- `platform.lock.yaml` 仍有 21 个 TODO，故脚本返回码为 `10`，平台不能宣称
  已完成可重建发布。

## Docker

已通过不依赖 daemon 的文本静态检查：Dockerfile、Compose 文件非空且无 tab。

当前机器事实：

- Docker client `26.1.3` 已安装；
- Docker Compose plugin 不可用；
- 当前用户无法访问 Docker daemon socket；
- NVIDIA container runtime 不可用。

因此本次不能进行真实 `docker build`、`docker compose config` 或容器 smoke。
这不是用宿主机结果冒充 Docker 验证；待 Compose、daemon、base image digest 和
源码 patch artifact 固定后，再执行真正的 Docker 构建验证。

## 当前结论

原生环境身份已被本机证据核对；Docker 配置文件已完成语法级检查；公共平台仍处于
`incomplete_local_baseline`。下一阶段是补齐 patch、apt/Python 锁、Docker digest
和 Docker 权限，然后重新执行原生验证与容器验证。多机实验尚未开始。
