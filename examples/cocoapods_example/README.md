# cocoapods_example

This example exists to verify that `nativeapi` and `cnativeapi` still build through CocoaPods on iOS and macOS.

Swift Package Manager is disabled for this project in `pubspec.yaml`:

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

Validation commands:

```sh
flutter build ios --no-codesign
flutter build macos
```
