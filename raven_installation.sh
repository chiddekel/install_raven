#!/bin/bash
set -euo pipefail

# ---------- packages (RHEL 10.2) ----------
# sudo dnf install -y epel-release || true
# sudo dnf install -y cmake gcc-c++ make python3 curl \
#   mingw64-gcc mingw64-gcc-c++ mingw32-gcc mingw32-gcc-c++ \
#   mingw64-crt mingw32-crt

# ---------- clone ----------
# sh8 failed: git clone into an existing ./raven (exit 128). Keep that tree.
if [[ ! -d raven/.git ]]; then
  git clone https://github.com/mirkobrombin/raven.git
fi
cd raven

# ---------- host warning fixes ----------
# sh18 rebuilt the native runtime with libpng found and printed warning:
# from -Wall -Wextra -Wpedantic -Wconversion. Each site is changed in the
# source. The same replacements are a no-op when they are already applied.
python3 - --write << 'PY'
#!/usr/bin/env python3
"""Idempotent source fixes for the warnings recorded in sh18.log.

Each replacement is applied only when the old text is still present.
A second run finds the new text and leaves the file unchanged.
"""
import hashlib
import sys
from pathlib import Path

REPLACEMENTS = []


def add(path, old, new):
    REPLACEMENTS.append((path, old, new))


add(
    "native/nt/file_api.cpp",
    "\t\trequest.l_type = kind;",
    "\t\trequest.l_type = static_cast<short>(kind);",
)
add(
    "native/nt/file_api.cpp",
    "registry.add(entry.name, entry.arguments,",
    "registry.add(entry.name, uint32_t(entry.arguments),",
)
add(
    "native/nt/registry_api.cpp",
    "registry.add(entry.name, entry.arguments,",
    "registry.add(entry.name, uint32_t(entry.arguments),",
)
add(
    "native/nt/winsock_api.cpp",
    "\t\tconst uint64_t overlapped = call[7], buffer = call[2], local_length = call.u32(4), remote_length = call.u32(5);",
    "\t\tconst uint64_t overlapped = call[7], buffer = call[2];\n"
    "\t\tconst uint32_t local_length = call.u32(4), remote_length = call.u32(5);",
)
add(
    "native/nt/crypt32_api.cpp",
    "registry.add(name, count, [](ApiCall &call) { call.ret(0x80090029U); });",
    "registry.add(name, uint32_t(count), [](ApiCall &call) { call.ret(0x80090029U); });",
)
add(
    "native/nt/authenticode.cpp",
    "for (const uint16_t flag : {1, 2})",
    "for (const uint16_t flag : {uint16_t{1}, uint16_t{2}})",
)
add(
    "native/nt/font_service.cpp",
    "\t\tinfo[14] = face->bbox.xMin;\n"
    "\t\tinfo[15] = face->bbox.yMin;\n"
    "\t\tinfo[16] = face->bbox.xMax;\n"
    "\t\tinfo[17] = face->bbox.yMax;",
    "\t\tinfo[14] = int32_t(face->bbox.xMin);\n"
    "\t\tinfo[15] = int32_t(face->bbox.yMin);\n"
    "\t\tinfo[16] = int32_t(face->bbox.xMax);\n"
    "\t\tinfo[17] = int32_t(face->bbox.yMax);",
)
add(
    "native/nt/thread_api.cpp",
    "thread->apcs.push_back({call[0], call[2]});",
    "thread->apcs.push_back({call[0], call[2], {}});",
)
add(
    "native/nt/text_api.cpp",
    "for (const auto suffix : {std::string(\"A\"), std::string(\"W\")})",
    "for (const auto &suffix : {std::string(\"A\"), std::string(\"W\")})",
)
add(
    "native/desktop/user_api.cpp",
    "for (const auto suffix : {std::string(\"A\"), std::string(\"W\")})",
    "for (const auto &suffix : {std::string(\"A\"), std::string(\"W\")})",
)
add(
    "native/desktop/user_ext.cpp",
    "const auto call_wide = [this](ApiCall &call, uint64_t window, uint32_t message, uint64_t wparam, uint64_t lparam)",
    "const auto call_wide = [this](ApiCall &, uint64_t window, uint32_t message, uint64_t wparam, uint64_t lparam)",
)
add(
    "native/desktop/gdi.cpp",
    "if (double(dx) * dx + double(dy) * dy <= radius * radius + 0.25",
    "if (double(dx) * double(dx) + double(dy) * double(dy) <= radius * radius + 0.25",
)
add(
    "native/desktop/gdi.cpp",
    "const double rx = rounded ? std::min<double>(round_w, double(width)) / 2.0 : width / 2.0;",
    "const double rx = rounded ? std::min<double>(double(round_w), double(width)) / 2.0 : double(width) / 2.0;",
)
add(
    "native/desktop/gdi.cpp",
    "const double ry = rounded ? std::min<double>(round_h, double(height)) / 2.0 : height / 2.0;",
    "const double ry = rounded ? std::min<double>(double(round_h), double(height)) / 2.0 : double(height) / 2.0;",
)
add(
    "native/desktop/gdi.cpp",
    "const double center_y = row + 0.5;",
    "const double center_y = double(row) + 0.5;",
)
add(
    "native/desktop/gdi.cpp",
    "else if (center_y > height - ry)",
    "else if (center_y > double(height) - ry)",
)
add(
    "native/desktop/gdi.cpp",
    "dy = center_y - (height - ry);",
    "dy = center_y - (double(height) - ry);",
)
add(
    "native/desktop/gdi.cpp",
    "const double dy = (center_y - height / 2.0) / (height / 2.0);",
    "const double dy = (center_y - double(height) / 2.0) / (double(height) / 2.0);",
)
add(
    "native/desktop/gdi.cpp",
    "const double half = (width / 2.0) * std::sqrt(std::max(0.0, 1.0 - dy * dy));",
    "const double half = (double(width) / 2.0) * std::sqrt(std::max(0.0, 1.0 - dy * dy));",
)
add(
    "native/desktop/gdi.cpp",
    "const double center_x = left + width / 2.0;",
    "const double center_x = double(left) + double(width) / 2.0;",
)
add(
    "native/desktop/gdi.cpp",
    "const double center = y + 0.5;",
    "const double center = double(y) + 0.5;",
)
add(
    "native/desktop/gdi_api.cpp",
    "// COLORREF to 0x00RRGGBB.\nuint32_t to_rgb(uint32_t color) { return colorref(color); }\n",
    "",
)
add(
    "native/desktop/gdi_api.cpp",
    "region.add({int32_t(left + std::floor(inset + 0.5)), int32_t(y), int32_t(right - std::floor(inset + 0.5)), int32_t(y + 1)});",
    "region.add({int32_t(double(left) + std::floor(inset + 0.5)), int32_t(y), int32_t(double(right) - std::floor(inset + 0.5)), int32_t(y + 1)});",
)
add(
    "native/desktop/brush.cpp",
    "bool fill_rect(NativeProcess &process,DesktopObjects &objects,uint64_t handle,DesktopRect rect,uint64_t brush_handle)",
    "bool fill_rect(NativeProcess &,DesktopObjects &objects,uint64_t handle,DesktopRect rect,uint64_t brush_handle)",
)
add(
    "native/desktop/bitblt.cpp",
    "bool bit_blt(NativeProcess &process,DesktopObjects &objects,std::span<const uint64_t> args)",
    "bool bit_blt(NativeProcess &,DesktopObjects &objects,std::span<const uint64_t> args)",
)
add(
    "native/desktop/frame.cpp",
    "\tconst int32_t width = window.outer.right - window.outer.left, height = window.outer.bottom - window.outer.top;",
    "\tconst int32_t width = window.outer.right - window.outer.left;",
)
add(
    "native/nt/providers.cpp",
    "\tKernelContext kernel{process, environment, memory, allocator, kernel_objects, threads, paths, modules, entry, *launch, invoke};",
    "\tKernelContext kernel{process, environment, memory, allocator, kernel_objects, threads, paths, modules, entry, *launch, invoke, 0, false, {}, {}, {}, {}, {}};",
)
add(
    "native/nt/x86_process.cpp",
    "\tKernelContext kernel{process, environment, memory, allocator, kernel_objects, guest_threads, paths, modules, entry, *launch, invoke};",
    "\tKernelContext kernel{process, environment, memory, allocator, kernel_objects, guest_threads, paths, modules, entry, *launch, invoke, 0, false, {}, {}, {}, {}, {}};",
)
add(
    "native/nt/x86_process.cpp",
    "[](std::string_view name) { return uint32_t(0); }",
    "[](std::string_view) { return uint32_t(0); }",
)
add(
    "native/nt/x86_process.cpp",
    "\tstatic constexpr std::array<std::string_view, 1> controls_exports{\"InitCommonControlsEx\"};\n",
    "",
)
add(
    "native/nt/providers.cpp",
    "\t\tconst unsigned __int128 multiplier = (static_cast<unsigned __int128>(ticks - calibration->ticks) << 32) / (counter - calibration->counter);\n"
    "\t\t__atomic_store_n(&published[2], static_cast<uint64_t>(multiplier), __ATOMIC_RELEASE);",
    "\t\tconst uint64_t numer = ticks - calibration->ticks;\n"
    "\t\tconst uint64_t denom = counter - calibration->counter;\n"
    "\t\tconst uint64_t quotient = numer / denom;\n"
    "\t\tuint64_t remainder = numer % denom;\n"
    "\t\tuint64_t extra = 0;\n"
    "\t\tfor (int bit = 0; bit < 32; ++bit) {\n"
    "\t\t\textra <<= 1;\n"
    "\t\t\tconst uint64_t carry = remainder >> 63;\n"
    "\t\t\tremainder <<= 1;\n"
    "\t\t\tif (carry || remainder >= denom) {\n"
    "\t\t\t\tremainder -= denom;\n"
    "\t\t\t\textra |= 1;\n"
    "\t\t\t}\n"
    "\t\t}\n"
    "\t\tconst uint64_t multiplier = (quotient << 32) + extra;\n"
    "\t\t__atomic_store_n(&published[2], multiplier, __ATOMIC_RELEASE);",
)
add(
    "native/graphics/vulkan_marshal.cpp",
    "\tVkPhysicalDeviceDescriptorBufferPropertiesEXT descriptor{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_BUFFER_PROPERTIES_EXT};\n"
    "\tVkPhysicalDeviceProperties2 properties{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2, &descriptor};",
    "\tVkPhysicalDeviceDescriptorBufferPropertiesEXT descriptor{};\n"
    "\tdescriptor.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_BUFFER_PROPERTIES_EXT;\n"
    "\tVkPhysicalDeviceProperties2 properties{};\n"
    "\tproperties.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;\n"
    "\tproperties.pNext = &descriptor;",
)
add(
    "native/graphics/vulkan_foreign.cpp",
    "\tVkBufferCreateInfo buffer{VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};",
    "\tVkBufferCreateInfo buffer{};\n\tbuffer.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;",
)
add(
    "native/graphics/vulkan_foreign.cpp",
    "VkCommandBufferBeginInfo begin{VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,nullptr,VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT};",
    "VkCommandBufferBeginInfo begin{VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,nullptr,VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,nullptr};",
)
add(
    "native/graphics/vulkan_bridge.h",
    "\t\tstd::vector<uint8_t> snapshot;",
    "\t\tstd::vector<uint8_t> snapshot{};",
)
add(
    "native/graphics/vulkan_generated.cpp",
    "VkHeadlessSurfaceCreateInfoEXT info{VK_STRUCTURE_TYPE_HEADLESS_SURFACE_CREATE_INFO_EXT};",
    "VkHeadlessSurfaceCreateInfoEXT info{};\n\t\t\t\tinfo.sType = VK_STRUCTURE_TYPE_HEADLESS_SURFACE_CREATE_INFO_EXT;",
)
add(
    "native/graphics/vulkan_resources.cpp",
    "\tconst auto buffer_of = [&](uint64_t token, uint64_t device) -> Buffer & {\n"
    "\t\tconst auto found = buffers.find(token);\n"
    "\t\tif (found == buffers.end() || found->second.device != device)\n"
    "\t\t\tthrow std::runtime_error(\"invalid Vulkan buffer handle\");\n"
    "\t\treturn found->second;\n"
    "\t};\n",
    "",
)
add(
    "native/graphics/vulkan_resources.cpp",
    "\tconst auto fence_of = [&](uint64_t token, uint64_t device) -> Fence & {\n"
    "\t\tconst auto found = fences.find(token);\n"
    "\t\tif (found == fences.end() || found->second.device != device)\n"
    "\t\t\tthrow std::runtime_error(\"invalid Vulkan fence handle\");\n"
    "\t\treturn found->second;\n"
    "\t};\n",
    "",
)
add(
    "native/nt/firmware_test.cpp",
    "\ttable.insert(table.end(), {127, 4, 0, 0, 0, 0});",
    "\tconst uint8_t end_marker[] = {127, 4, 0, 0, 0, 0};\n"
    "\ttable.insert(table.end(), end_marker, end_marker + 6);",
)
add(
    "native/upstream/reactos-utf8/decode.inc",
    "            utf16_ch[0] = ch;",
    "            utf16_ch[0] = WCHAR(ch);",
)
add(
    "native/upstream/reactos-utf8/decode.inc",
    "                uni_bytes_max -= sizeof(WCHAR);",
    "                uni_bytes_max -= ULONG(sizeof(WCHAR));",
)


def apply_one(path, old, new, write):
    file = Path(path)
    text = file.read_text()
    if old == "":
        raise SystemExit(f"empty old text for {path}")
    found = text.count(old)
    if found == 0:
        if new == "" or new in text:
            print(f"already patched {path}")
            return False
        raise SystemExit(f"anchor missing in {path}: {old[:120]!r}")
    if found != 1:
        raise SystemExit(f"{path}: expected 1 occurrence, found {found}: {old[:80]!r}")
    updated = text.replace(old, new, 1)
    if write and updated != text:
        file.write_text(updated)
        print(f"patched {path}")
    elif not write:
        print(f"would patch {path}")
    return True


def pin_decode(write):
    data = Path("native/upstream/reactos-utf8/decode.inc").read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    cmake = Path("native/CMakeLists.txt")
    text = cmake.read_text()
    needle = 'upstream/reactos-utf8/decode.inc UTF8_SOURCE_HASH)\n    if(NOT UTF8_SOURCE_HASH STREQUAL "'
    index = text.find(needle)
    if index < 0:
        raise SystemExit("decode hash pin not found")
    start = index + len(needle)
    if text[start + 64:start + 66] != '")':
        raise SystemExit("decode hash pin shape differs")
    if text[start:start + 64] != digest:
        text = text[:start] + digest + text[start + 64:]
        if write:
            cmake.write_text(text)
            print(f"updated CMakeLists decode hash {digest}")
        else:
            print(f"would update CMakeLists decode hash {digest}")
    else:
        print("CMakeLists decode hash already matches")
    prov = Path("native/upstream/reactos-utf8/provenance.json")
    ptext = prov.read_text()
    key = '"decode_inc_sha256": "'
    at = ptext.find(key)
    if at < 0:
        raise SystemExit("provenance decode hash missing")
    ps = at + len(key)
    if ptext[ps + 64:ps + 65] != '"':
        raise SystemExit("provenance decode hash shape differs")
    if ptext[ps:ps + 64] != digest:
        ptext = ptext[:ps] + digest + ptext[ps + 64:]
        if write:
            prov.write_text(ptext)
            print(f"updated provenance decode hash {digest}")
        else:
            print(f"would update provenance decode hash {digest}")
    else:
        print("provenance decode hash already matches")


def main():
    write = "--write" in sys.argv
    for path, old, new in REPLACEMENTS:
        apply_one(path, old, new, write)
    pin_decode(write)


if __name__ == "__main__":
    main()
PY

# ---------- header patches (idempotent) ----------
# sh9 failed: sed appended the same DEFINE_GUID blocks twice, so
# taskschd.c and uisettings.c redefined IID_* (gmake exit 2).
python3 - << 'PY'
from pathlib import Path

def ensure_once(path, anchor, block):
    p = Path(path)
    text = p.read_text()
    if not block.endswith("\n"):
        block += "\n"
    removed = 0
    while block in text:
        text = text.replace(block, "", 1)
        removed += 1
    idx = text.find(anchor)
    if idx < 0:
        raise SystemExit(f"anchor missing in {path}: {anchor}")
    insert_at = idx + len(anchor)
    if insert_at < len(text) and text[insert_at] == "\n":
        insert_at += 1
    new = text[:insert_at] + block + text[insert_at:]
    if new != p.read_text():
        p.write_text(new)
        print(f"{path}: rewrote (removed {removed} copies)")
    else:
        print(f"{path}: already one copy")

ensure_once(
    "testdata/native_loader/bcrypt_client.c",
    "#include <bcrypt.h>",
    """#ifndef BCRYPT_SHA256_ALG_HANDLE
#define BCRYPT_SHA256_ALG_HANDLE ((BCRYPT_ALG_HANDLE)0x00000041)
#endif
#ifndef BCRYPT_SHA1_ALG_HANDLE
#define BCRYPT_SHA1_ALG_HANDLE ((BCRYPT_ALG_HANDLE)0x00000031)
#endif
#ifndef BCRYPT_SHA384_ALG_HANDLE
#define BCRYPT_SHA384_ALG_HANDLE ((BCRYPT_ALG_HANDLE)0x00000051)
#endif
#ifndef BCRYPT_SHA512_ALG_HANDLE
#define BCRYPT_SHA512_ALG_HANDLE ((BCRYPT_ALG_HANDLE)0x00000061)
#endif
#ifndef BCRYPT_MD5_ALG_HANDLE
#define BCRYPT_MD5_ALG_HANDLE ((BCRYPT_ALG_HANDLE)0x00000021)
#endif
""",
)
ensure_once(
    "native/upstream/raven-taskschd/taskschd.c",
    "#include <taskschd.h>",
    """#ifndef IID_ILogonTrigger
DEFINE_GUID(IID_ILogonTrigger, 0x72dade38, 0xfae4, 0x4b3e, 0xba, 0xf4, 0x5d, 0x00, 0x9a, 0xf0, 0x2b, 0x1c);
#endif
#ifndef IID_IBootTrigger
DEFINE_GUID(IID_IBootTrigger, 0x2a9c35da, 0xd357, 0x41f4, 0xbb, 0xc1, 0x20, 0x7a, 0xc1, 0xb1, 0xf3, 0xcb);
#endif
""",
)
ensure_once(
    "native/upstream/raven-deployment/deployment.c",
    "#include <windows.h>",
    """#ifndef E_BOUNDS
#define E_BOUNDS ((HRESULT)0x8000000BL)
#endif
""",
)
ensure_once(
    "native/upstream/raven-uisettings/uisettings.c",
    "#include <windows.h>",
    """#ifndef IID___x_ABI_CWindows_CUI_CViewManagement_CIUISettings4
DEFINE_GUID(IID___x_ABI_CWindows_CUI_CViewManagement_CIUISettings4, 0x52bb3002, 0x919b, 0x4d6b, 0x9b, 0x78, 0x8d, 0xd6, 0x6f, 0xf4, 0xb9, 0x3b);
#endif
#ifndef IID___x_ABI_CWindows_CUI_CViewManagement_CIUISettings5
DEFINE_GUID(IID___x_ABI_CWindows_CUI_CViewManagement_CIUISettings5, 0x5349d588, 0x0cb5, 0x5f05, 0xbd, 0x34, 0x70, 0x6b, 0x32, 0x31, 0xf0, 0xbd);
#endif
#ifndef IID___x_ABI_CWindows_CUI_CViewManagement_CIUISettings6
DEFINE_GUID(IID___x_ABI_CWindows_CUI_CViewManagement_CIUISettings6, 0xaef19bd7, 0xfe31, 0x5a04, 0xad, 0xa4, 0x46, 0x9a, 0xae, 0xc6, 0xdf, 0xa9);
#endif
#ifndef __x_ABI_CWindows_CUI_CViewManagement_CIUISettings4Vtbl
typedef struct __x_ABI_CWindows_CUI_CViewManagement_CIUISettings4Vtbl { void *QueryInterface; void *AddRef; void *Release; void *GetIids; void *GetRuntimeClassName; void *GetTrustLevel; void *get_AdvancedEffectsEnabled; void *add_AdvancedEffectsEnabledChanged; void *remove_AdvancedEffectsEnabledChanged; } __x_ABI_CWindows_CUI_CViewManagement_CIUISettings4Vtbl;
typedef struct __x_ABI_CWindows_CUI_CViewManagement_CIUISettings4 { const __x_ABI_CWindows_CUI_CViewManagement_CIUISettings4Vtbl *lpVtbl; } __x_ABI_CWindows_CUI_CViewManagement_CIUISettings4;
#endif
#ifndef __x_ABI_CWindows_CUI_CViewManagement_CIUISettings5Vtbl
typedef struct __x_ABI_CWindows_CUI_CViewManagement_CIUISettings5Vtbl { void *QueryInterface; void *AddRef; void *Release; void *GetIids; void *GetRuntimeClassName; void *GetTrustLevel; void *get_AutoHideScrollBars; void *add_AutoHideScrollBarsChanged; void *remove_AutoHideScrollBarsChanged; } __x_ABI_CWindows_CUI_CViewManagement_CIUISettings5Vtbl;
typedef struct __x_ABI_CWindows_CUI_CViewManagement_CIUISettings5 { const __x_ABI_CWindows_CUI_CViewManagement_CIUISettings5Vtbl *lpVtbl; } __x_ABI_CWindows_CUI_CViewManagement_CIUISettings5;
#endif
#ifndef __x_ABI_CWindows_CUI_CViewManagement_CIUISettings6Vtbl
typedef struct __x_ABI_CWindows_CUI_CViewManagement_CIUISettings6Vtbl { void *QueryInterface; void *AddRef; void *Release; void *GetIids; void *GetRuntimeClassName; void *GetTrustLevel; void *add_AnimationsEnabledChanged; void *remove_AnimationsEnabledChanged; void *add_MessageDurationChanged; void *remove_MessageDurationChanged; } __x_ABI_CWindows_CUI_CViewManagement_CIUISettings6Vtbl;
typedef struct __x_ABI_CWindows_CUI_CViewManagement_CIUISettings6 { const __x_ABI_CWindows_CUI_CViewManagement_CIUISettings6Vtbl *lpVtbl; } __x_ABI_CWindows_CUI_CViewManagement_CIUISettings6;
#endif
""",
)
PY

# ---------- webservices ----------
curl -fsSL -o native/upstream/raven-webservices/webservices.h \
  "https://raw.githubusercontent.com/wine-mirror/wine/master/include/webservices.h"
python3 - << 'PY'
from pathlib import Path
for rel in (
    "native/upstream/raven-webservices/webservices.c",
    "testdata/native_loader/webservices_client.c",
):
    p = Path(rel)
    text = p.read_text()
    new = text.replace("#include <webservices.h>", '#include "webservices.h"')
    if new != text:
        p.write_text(new)
        print(f"{rel}: include rewritten")
    else:
        print(f"{rel}: include already local")
PY
cp native/upstream/raven-webservices/webservices.h testdata/native_loader/webservices.h

# ---------- sincos stub for provision-installer ----------
# MinGW 15 turns paired sin/cos into sincos, which libm does not provide.
# urlmon calls _recalloc, which exists in UCRT but not in msvcrt.dll.
# -O0 -fno-builtin keeps these stubs from being rewritten into the missing calls.
cat > scripts/sincos_stub.c << 'EOF'
typedef __SIZE_TYPE__ size_t;
__declspec(dllimport) double sin(double);
__declspec(dllimport) double cos(double);
__declspec(dllimport) void *realloc(void *, size_t);
__declspec(dllimport) void *calloc(size_t, size_t);
__declspec(dllimport) size_t _msize(void *);
__declspec(dllimport) void *memset(void *, int, size_t);

void sincos(double x, double *sinx, double *cosx) {
    *sinx = sin(x);
    *cosx = cos(x);
}

void *_recalloc(void *mem, size_t count, size_t size) {
    size_t bytes, old;
    void *next;
    if (count && size > ((size_t)-1) / count)
        return 0;
    bytes = count * size;
    if (!mem)
        return calloc(count, size);
    old = _msize(mem);
    next = realloc(mem, bytes);
    if (!next)
        return 0;
    if (bytes > old)
        memset((char *)next + old, 0, bytes - old);
    return next;
}
EOF
x86_64-w64-mingw32-gcc -c -O0 -fno-builtin -o scripts/sincos_stub.o scripts/sincos_stub.c
i686-w64-mingw32-gcc -c -O0 -fno-builtin -o scripts/sincos_stub32.o scripts/sincos_stub.c

# Patch provision-installer.py to link the CRT stub.
# sh13 linked the stub into msftedit.dll, which does not pull in msvcrt,
# so __imp_sin and the realloc imports stayed undefined.
python3 - << 'PY'
from pathlib import Path
p = Path("scripts/provision-installer.py")
text = p.read_text()
broken = (
    "    def link(name, base, object_files, definition, libraries, implib=None):\n"
    "    stub = Path(__file__).parent / \"sincos_stub.o\"\n"
    "    if stub.exists():\n"
    "        object_files = list(object_files) + [stub]\n"
)
partial = (
    "    def link(name, base, object_files, definition, libraries, implib=None):\n"
    "        stub = Path(__file__).parent / \"sincos_stub.o\"\n"
    "        if stub.exists():\n"
    "            object_files = list(object_files) + [stub]\n"
)
fixed = (
    "    def link(name, base, object_files, definition, libraries, implib=None):\n"
    "        stub = Path(__file__).parent / \"sincos_stub.o\"\n"
    "        if stub.exists():\n"
    "            object_files = list(object_files) + [stub]\n"
    "            if \"-lmsvcrt\" not in libraries and msvcrt not in libraries:\n"
    "                libraries = list(libraries) + [msvcrt]\n"
)
clean = "    def link(name, base, object_files, definition, libraries, implib=None):\n"
if fixed in text:
    print("provision-installer.py: stub already links msvcrt")
elif partial in text:
    p.write_text(text.replace(partial, fixed, 1))
    print("provision-installer.py: stub now pulls msvcrt")
elif broken in text:
    p.write_text(text.replace(broken, fixed, 1))
    print("provision-installer.py: replaced broken stub indent")
elif clean in text:
    p.write_text(text.replace(clean, fixed, 1))
    print("provision-installer.py: stub inserted")
else:
    raise SystemExit("provision-installer.py link() signature not found")
PY
python3 -m py_compile scripts/provision-installer.py

# ---------- libpng ----------
# sh14 printed CMake Warning twice: libpng 1.6.59 was not found.
export RAVEN_COMPONENTS_DIR="$HOME/.local/share/raven-components"
mkdir -p "$RAVEN_COMPONENTS_DIR"
png_line=$(python3 scripts/provision-libpng.py --output "$RAVEN_COMPONENTS_DIR/libpng")
echo "$png_line"
# sh16: the script prints install/lib, but this host installs into install/lib64,
# and FindPNG then recorded a library path that does not exist.
png_root="$RAVEN_COMPONENTS_DIR/libpng/install"
if [[ -f "$png_root/lib/libpng16.a" ]]; then
  png_lib="$png_root/lib/libpng16.a"
elif [[ -f "$png_root/lib64/libpng16.a" ]]; then
  png_lib="$png_root/lib64/libpng16.a"
else
  echo "libpng static library not found under $png_root" >&2
  exit 1
fi
png_inc="$png_root/include"
test -f "$png_inc/png.h"
# sh17 set MAP_IMPORTED_CONFIG_RELWITHDEBINFO=RELEASE. That hid PNG's missing
# file and then rejected OpenSSL::Crypto, which only has IMPORTED_LOCATION.
PNG_CMAKE=(
  -DPNG_LIBRARY="$png_lib"
  -DPNG_LIBRARY_RELEASE="$png_lib"
  -DPNG_PNG_INCLUDE_DIR="$png_inc"
)
echo "using libpng $png_lib"

# ---------- configure & build ----------
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -UCMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO \
  "${PNG_CMAKE[@]}"
JOBS=$(( $(nproc) > 8 ? 8 : $(nproc) ))
echo "Building with -j${JOBS}"
cmake --build build -j"${JOBS}"

# ---------- provision ----------

python3 scripts/provision-rtl.py --output "$RAVEN_COMPONENTS_DIR/rtl"
python3 scripts/provision-controls.py --output "$RAVEN_COMPONENTS_DIR/controls64" --arch x64
python3 scripts/provision-controls.py --output "$RAVEN_COMPONENTS_DIR/controls32" --arch x86

# installer (64 then 32, swapping stub)
python3 scripts/provision-installer.py --output "$RAVEN_COMPONENTS_DIR/installer64" --arch x64
cp scripts/sincos_stub32.o scripts/sincos_stub.o
python3 scripts/provision-installer.py --output "$RAVEN_COMPONENTS_DIR/installer32" --arch x86

python3 scripts/provision-text.py --output "$RAVEN_COMPONENTS_DIR/text"
python3 scripts/provision-roots.py --output "$RAVEN_COMPONENTS_DIR/roots"

# ---------- final rebuild with components ----------
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -UCMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO \
  "${PNG_CMAKE[@]}" \
  -DRAVEN_CONTROLS_COMPONENT_DIR="$RAVEN_COMPONENTS_DIR/controls64" \
  -DRAVEN_CONTROLS32_COMPONENT_DIR="$RAVEN_COMPONENTS_DIR/controls32" \
  -DRAVEN_INSTALLER_COMPONENT_DIR="$RAVEN_COMPONENTS_DIR/installer64" \
  -DRAVEN_INSTALLER32_COMPONENT_DIR="$RAVEN_COMPONENTS_DIR/installer32" \
  -DRAVEN_TEXT_COMPONENT_PATH="$RAVEN_COMPONENTS_DIR/text/raven-text.dll" \
  -DRAVEN_RTL_COMPONENT_PATH="$RAVEN_COMPONENTS_DIR/rtl/raven-rtl.dll" \
  -DRAVEN_ROOT_CERTIFICATE_DIRECTORY="$RAVEN_COMPONENTS_DIR/roots"

cmake --build build -j"${JOBS}"

test -s build/native/raven
file build/native/raven | grep -q 'ELF'
echo ""
echo "Done."
ls -la build/native/raven
