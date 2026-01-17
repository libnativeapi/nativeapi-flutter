# nativeapi

[nativeapi](https://github.com/libnativeapi/libnativeapi) 的 Flutter 绑定 - 提供无缝、统一的原生系统 API 访问。

🚧 **开发中**: 此包目前正在积极开发中。

## 快速开始

在 `pubspec.yaml` 中添加 `nativeapi`:

```yaml
dependencies:
  nativeapi: ^0.1.0
```

然后运行:

```bash
flutter pub get
```

### 使用方法

> 📖 详细的文档和示例即将推出！

```dart
import 'package:nativeapi/nativeapi.dart';

// 示例用法将在此处添加
```

## 开发

### 前置要求

- Flutter (>=3.35.0)
- Dart SDK (>=3.9.0)

### 设置

1. 克隆仓库:

```bash
git clone https://github.com/libnativeapi/nativeapi-flutter.git
cd nativeapi-flutter
```

2. 初始化子模块:

```bash
git submodule update --init --recursive
```

3. 安装依赖:

```bash
melos bootstrap
```

4. 运行示例应用:

```bash
cd examples/display_example
flutter run
```

### FFI 绑定

本项目使用 ffigen 从 C 头文件生成 Dart FFI 绑定。要重新生成绑定:

```bash
cd packages/cnativeapi
dart run ffigen --config ffigen.yaml
```

ffigen 配置定义在 `packages/cnativeapi/ffigen.yaml` 中。通常在以下情况下需要重新生成绑定：
- 原生 C 库 ([libnativeapi/nativeapi](https://github.com/libnativeapi/nativeapi)) 更新时
- ffigen 配置被修改时

## 许可证

[MIT](./LICENSE)
