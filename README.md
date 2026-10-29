# instant

One-shot build script for [raven](https://github.com/mirkobrombin/raven) on RHEL 10.2.

> **Tested on Red Hat Enterprise Linux 10.2.** Other RHEL-family releases (Rocky, Alma, CentOS Stream) may work but are untested.

`raven_installation.sh` clones raven, applies a set of reproducible source patches, provisions native components (libpng, RTL, controls, installer, text, roots), and produces a working Linux binary at `build/native/raven`.

## What it does

1. **Clone** — fetches `mirkobrombin/raven` into `./raven` if not already present.
2. **Patch (idempotent)** — applies `-Wall -Wextra -Wpedantic -Wconversion` warning fixes via a Python replacement table that only fires when the old text is still present. Also re-pins the SHA-256 of `decode.inc` in both `CMakeLists.txt` and `provenance.json`.
3. **Header patches (idempotent)** — inserts missing `GUID`/`HRESULT` definitions behind `#ifndef` guards, exactly once, so re-runs don't duplicate symbols.
4. **Webservices** — downloads `webservices.h` from wine-mirror, rewrites `#include <webservices.h>` to the local copy, and copies the header into the loader test data.
5. **CRT stub** — builds 64-bit and 32-bit `sincos` / `_recalloc` stubs for MinGW (MinGW 15 emits `sincos`, which glibc's libm does not provide; `urlmon` calls `_recalloc`, which exists only in UCRT). Compiled `-O0 -fno-builtin` so the stubs themselves aren't rewritten into the missing calls.
6. **libpng** — provisions libpng 1.6 into `~/.local/share/raven-components/libpng`, accepting either `lib/` or `lib64/` install layouts on the host.
7. **Build** — `cmake` configure + build in `RelWithDebInfo`, `lib/` vs `lib64/`-safe, capped at 8 parallel jobs.
8. **Provision** — runs the raven provisioning scripts for rtl, controls (x64 + x86), installer (x64 + x86), text, and root certificates.
9. **Rebuild & verify** — reconfigures with all component paths, rebuilds, then asserts a real ELF exists at `build/native/raven`.

## Requirements

- RHEL 10.2 (or compatible) with `sudo dnf`
- Build packages: `cmake`, `gcc-c++`, `make`, `python3`, `curl`
- MinGW cross toolchain: `mingw64-gcc`, `mingw64-gcc-c++`, `mingw32-gcc`, `mingw32-gcc-c++`, `mingw64-crt`, `mingw32-crt`
- Vulkan runtime headers (pulled in by the raven build)
- Network access (git clone + wine-mirror header fetch + component downloads)

```bash
sudo dnf install -y epel-release
sudo dnf install -y cmake gcc-c++ make python3 curl \
  mingw64-gcc mingw64-gcc-c++ mingw32-gcc mingw32-gcc-c++ \
  mingw64-crt mingw32-crt
```

## Quickstart

```bash
./raven_installation.sh
```

The script is safe to re-run: every patch step is a no-op once applied, and provisioning results are cached under `~/.local/share/raven-components`.

## Idempotency

Every patch layer is designed for repeated runs:

- Source replacements keep a table of `(path, old, new)` pairs; a second run sees the new text and skips.
- Header blocks are wrapped in `#ifndef` guards and re-insertions remove duplicates first.
- The decode-source hash pin is recomputed and only rewritten when the digest differs.

## Where things land

| Path | Purpose |
|------|---------|
| `./raven` | cloned upstream tree |
| `./raven/build/native/raven` | final Linux binary |
| `~/.local/share/raven-components` | provisioned components (png, rtl, controls, installer, text, roots) |

## Troubleshooting

The script encodes fixes for issues hit during earlier runs (logged in comments):

- **Clone conflict** — the script keeps an existing `./raven` tree instead of failing with exit 128.
- **Missing GUIDs** — `taskschd`, `uisettings`, `deployment`, and `bcrypt` headers rebuilt with guarded definitions.
- **`sincos` / `_recalloc` undefined imports** — handled by the CRT stub, linked only into targets that pull in `msvcrt`.
- **libpng not found / wrong lib dir** — explicit `PNG_LIBRARY` / `PNG_PNG_INCLUDE_DIR` CMake variables bypass broken `FindPNG` behavior.
- **Suppressed imported-config mismatch** — `CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO` is unset so imported targets aren't silently rejected.

## Status

Verified on Red Hat Enterprise Linux 10.2 (x86_64). Unofficial, environment-specific install path. Not affiliated with the upstream raven project.
