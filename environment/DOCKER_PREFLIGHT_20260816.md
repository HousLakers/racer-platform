# Docker preflight — 2026-08-16

## Static checks

- `docker/compose.yaml` parsed successfully with PyYAML;
- all repository shell scripts pass `bash -n`;
- Dockerfile and Compose files require explicit image variables rather than using
  floating defaults;
- Dockerfile and Compose SHA256 were captured during this preflight.

## Host status

- Docker client: `26.1.3`;
- Docker daemon access is available to the current user;
- Docker Compose v2 `5.1.2` is available;
- NVIDIA container runtime is unavailable.
- canonical Compose service is CPU-only; no `gpus: all`, NVIDIA environment variables,
  or GPU profile is shipped in the default configuration.

The CPU-only path has now passed real `docker compose config`, image build, and
runtime smoke checks. The container reported ROS `noetic` and PyYAML `6.0.3`.
GPU and GUI smoke checks remain intentionally unexecuted.

The project deliberately does not require GPU access. Ubuntu's discrete-GPU-direct
display mode is a host display choice and does not by itself require GPU containers;
the CPU-only container path avoids CUDA/NVIDIA runtime coupling.

## Recorded build identity

- Base image: `ros:noetic-ros-base-focal@sha256:72b8bc59035dc0a5b8e07aae28c16caa84192971d72d207c72ed734fb1d5e97d`;
- Output image: `racer-platform:local-cpu`;
- Output image ID: `sha256:b2b061ee67c9d88df7fa50e593a395e5c503da4629da4be59b791f66f5c7bd61`;
- Compute path: CPU-only; no NVIDIA runtime required.

## Remaining administrator action

If GPU mode is ever required, install/configure NVIDIA Container Toolkit. Do not
solve display access by using `xhost +` globally.

After that, run the Docker validation in this order:

```bash
docker compose version
docker compose -f docker/compose.yaml config --quiet
docker compose -f docker/compose.yaml run --rm racer-platform \
  bash -lc 'rosversion -d && python3 -c "import yaml; print(yaml.__version__)"'
```

The CPU-only image build is complete. Full source-backed reconstruction still
depends on the source patch and external asset contracts listed in
`environment/OPEN_ITEMS.md`.
