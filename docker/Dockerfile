# BASE_IMAGE is intentionally required. Pass an approved name@sha256 digest.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY environment/apt-packages.txt /opt/racer-platform/environment/apt-packages.txt
COPY environment/python-requirements.txt /opt/racer-platform/environment/python-requirements.txt

# Exact package versions are locked, but repository snapshot/key provenance is
# still an OPEN_ITEM. The build intentionally does not import project sources.
RUN sed -E '/^[[:space:]]*(#|$)/d' /opt/racer-platform/environment/apt-packages.txt \
      > /tmp/racer-apt-packages.txt \
    && apt-get update \
    && xargs -r apt-get install -y --no-install-recommends < /tmp/racer-apt-packages.txt \
    && rm -rf /var/lib/apt/lists/* /tmp/racer-apt-packages.txt

# Ubuntu focal supplies PyYAML through distutils; seed the locked wheel
# without asking pip to uninstall the distutils-owned files.
RUN python3 -m pip install --no-cache-dir pip==25.0.1 \
    && python3 -m pip install --no-cache-dir --ignore-installed PyYAML==6.0.3 \
    && python3 -m pip install --no-cache-dir \
      --requirement /opt/racer-platform/environment/python-requirements.txt

COPY platform.lock.yaml repos.repos repos.le8e.repos ENVIRONMENT_SYNC.md /opt/racer-platform/
COPY scripts/ /opt/racer-platform/scripts/

ENV ROS_DISTRO=noetic \
    RACER_PLATFORM_SOURCE_ROOT=/opt/racer-platform/sources \
    RACER_PLATFORM_WORK_ROOT=/workspace
WORKDIR /workspace

CMD ["/bin/bash"]
