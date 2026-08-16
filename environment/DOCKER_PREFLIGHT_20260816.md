# Docker preflight — 2026-08-16

## Static checks

- `docker/compose.yaml` parsed successfully with PyYAML;
- all repository shell scripts pass `bash -n`;
- Dockerfile and Compose files require explicit image variables rather than using
  floating defaults;
- Dockerfile and Compose SHA256 were captured during this preflight.

## Host blockers

- Docker client: `26.1.3`;
- Docker daemon socket exists at `/var/run/docker.sock`, but the current user cannot
  access it;
- current user is not a member of the `docker` group;
- Docker Compose v2 plugin is unavailable;
- apt exposes only legacy `docker-compose` `1.25.0-1`, which is not accepted as the
  Compose v2 release contract for this project;
- NVIDIA container runtime is unavailable.

Therefore no real `docker compose config`, `docker build`, `docker run`, GPU smoke or
GUI smoke was executed. The Docker configuration is syntactically prepared but not
runtime-validated.

## Required administrator action

Install a supported Compose v2 plugin, grant the intended user controlled access to
the Docker daemon, and if GPU mode is required install/configure NVIDIA Container
Toolkit. Do not solve this by silently installing the old Compose v1 package or by
using `xhost +` globally.

After that, run the Docker validation in this order:

```bash
docker compose version
docker compose config
docker build --build-arg BASE_IMAGE=<immutable-ros-base-digest> \
  -t <immutable-local-platform-tag> -f docker/Dockerfile .
docker run --rm <immutable-local-platform-tag> \
  /opt/racer-platform/scripts/verify_platform.sh --help
```

The actual build remains blocked until `platform.lock.yaml` records the immutable
base image digest and the Docker source/patch input contract.
