# Livox SDK dependency

## Fixed source

- repository: `https://github.com/Livox-SDK/Livox-SDK.git`
- commit: `9306596a2bf15c1343bc023b497465ed0a32909d`
- observed local checkout: `/home/houslakers/swarm_ws/src/Swarm-LIO2/livox_ros_driver_mars/Livox-SDK`
- reproducible platform import path: `${RACER_PLATFORM_SOURCE_ROOT}/Livox-SDK`

The SDK is an independent source dependency. It must not be treated as an opaque,
mutable subdirectory of Swarm-LIO2.

## Build contract

Build the SDK first so that this file exists:

```text
${LIVOX_SDK_ROOT}/build/sdk_core/liblivox_sdk_static.a
```

Then configure catkin with:

```bash
catkin_make -DCMAKE_BUILD_TYPE=Release \
  -DLIVOX_SDK_ROOT=/path/to/racer-platform/sources/Livox-SDK
```

The Livox ROS driver CMake patch disables its historical fallback that deletes the
SDK directory and clones from GitHub. Missing SDK now fails immediately with an
actionable error. Network download must happen only during an explicit source
import step, never during CMake configuration.

The SDK build directory is generated output and is not committed to GitHub.
