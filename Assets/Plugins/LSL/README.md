# LSL Native Plugin — Setup Instructions

This directory must contain the compiled liblsl native binary for your target
platform **before** running or building the Unity project.

## Download

1. Go to the official liblsl releases page:
   https://github.com/sccn/liblsl/releases

2. Download the appropriate archive for your platform:
   | Platform | File to download | Binary to copy here |
   |----------|-----------------|---------------------|
   | Windows 64-bit | `liblsl-*-Win_amd64.zip` | `liblsl64.dll` |
   | macOS (Intel) | `liblsl-*-OSX_amd64.tar.gz` | `liblsl64.dylib` |
   | macOS (Apple Silicon) | `liblsl-*-OSX_arm64.tar.gz` | `liblsl64.dylib` |
   | Linux 64-bit | `liblsl-*-Linux_amd64.tar.gz` | `liblsl64.so` |

3. Place the extracted binary in this directory
   (`Assets/Plugins/LSL/`).

## Unity Plugin Inspector Settings

After placing the binary, select it in the Unity Project window and configure
the **Plugin Inspector** in the Inspector panel:
- Set **Platform** to the correct target (e.g., *Editor* + *Standalone* for
  Windows).
- Ensure **CPU** is set to `x86_64` (or `ARM64` for Apple Silicon).

## Verifying the Setup

Open the Unity Editor Console.  When the scene starts, `LSLManager` will log:

```
[LSL] Outlet 'UnityTrialResults' created.
[LSL] Searching for MATLAB QUEST stream…
```

If you instead see a `DllNotFoundException`, the native binary is missing or
placed in the wrong location.
