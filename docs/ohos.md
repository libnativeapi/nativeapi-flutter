# OHOS branch

`ohos-main` merges the Flutter binding's `main` API and keeps the OHOS plugin
and application projects. The OHOS workspace contains `cnativeapi`, `nativeapi`,
`packages/cnativeapi/example`, and `examples/display_example`.

## SDK

Use the [CPF-Flutter SDK](https://gitcode.com/CPF-Flutter/flutter_flutter), branch
`oh-3.35.7-release` (Dart 3.9.2). On Windows, install DevEco Studio with its
HarmonyOS SDK, Node, OHPM, Hvigor and JBR components, then clone Flutter:

```powershell
git clone --branch oh-3.35.7-release --single-branch https://gitcode.com/CPF-Flutter/flutter_flutter.git "$env:USERPROFILE\fvm\versions\ohos-3.35.7"
$env:DEVECO_STUDIO_HOME = 'E:\Program Files\Huawei\DevEco Studio'
$env:FLUTTER_OHOS_HOME = "$env:USERPROFILE\fvm\versions\ohos-3.35.7"
```

Use a full clone, or fetch enough history and release tags for `git describe
--tags --match '*.*.*'` to succeed. Without tags Flutter reports `0.0.0-unknown`
and cannot validate package version constraints.

`tools/flutter_ohos.ps1` sets SDK paths and download sources for one command,
then restores the calling process's environment. Normal Flutter/FVM remains
independent. Persist the two paths above in user environment variables if needed.

```powershell
& .\tools\flutter_ohos.ps1 doctor -v
& .\tools\flutter_ohos.ps1 pub get
cd examples\display_example
& ..\..\tools\flutter_ohos.ps1 build hap --debug --no-codesign
cd ..\..\packages\cnativeapi\example
& ..\..\..\tools\flutter_ohos.ps1 build hap --debug --no-codesign
```

The normal Flutter artifacts and OHOS artifacts use different download hosts:
`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` and
`FLUTTER_OHOS_STORAGE_BASE_URL=https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com`.
Do not point both variables to the OHOS bucket: the upstream engine stamp is
not published there.

## Compatibility

The Dart packages and OHOS examples require Dart 3.9 / Flutter 3.35 or newer.
The separate `package:nativeapi/windowing.dart` desktop bridge and the desktop
multi-window examples still require upstream Flutter 3.47; they are retained
from `main` but are not part of the OHOS build. Import `nativeapi.dart` in OHOS
applications.

A successful HAP build verifies compilation and packaging. Many native OHOS
backends in core are still stubs; compilation does not imply full platform
feature support. Installing on a device additionally requires a local signing
configuration from DevEco Studio.

## Verified toolchain

Verified on Windows with DevEco Studio 26.0.0.105 (HarmonyOS API 26),
CPF-Flutter `oh-3.35.7-release` at `3dbfa8d7e153f7c2a3a75aca7e52b32a00f4b9b6`
(reported version `3.35.8-ohos-1.0.4`), and Dart 3.9.2:

- `display_example`: arm64 debug and release unsigned HAPs.
- `cnativeapi/example`: arm64 debug unsigned HAP.

The checked-in target SDK remains API 20 with compatibility down to API 18.
No device signing credentials or machine-specific SDK paths belong in the
OHOS project files.
