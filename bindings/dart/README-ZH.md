# nativeapi 的 Dart 与 Flutter 绑定

[nativeapi](https://github.com/libnativeapi/nativeapi-core) 的 Dart 与 Flutter 绑定，统一访问原生系统 API：窗口、托盘图标、菜单、显示器、键盘、对话框、存储等。

| Android | iOS | Linux | macOS | Windows |
|:-------:|:---:|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

🚧 **开发中**：此包正在积极开发中。

[English](./README.md) | 简体中文

## 包

| 包 | 说明 |
| --- | --- |
| [`nativeapi`](nativeapi) | API 本身：窗口、托盘图标、菜单、显示器、键盘、对话框、存储等。纯 Dart，不依赖 Flutter。 |
| [`cnativeapi`](cnativeapi) | 面向 core C ABI 的原始 FFI 绑定，由 build hook 编译 core，供 `nativeapi` 使用。 |
| [`nativeapi_flutter`](nativeapi_flutter) | 给 Flutter 应用用：重新导出 `nativeapi`，并提供 widget、与 `dart:ui` 类型的互转和多窗口桥接。 |

## 安装

Flutter 应用：

```bash
flutter pub add nativeapi_flutter
```

Dart 应用（命令行或其他 Dart 宿主）：

```bash
dart pub add nativeapi
```

`nativeapi` 有自己的 `Point`、`Size`、`Rectangle`、`Color` 类型。`nativeapi_flutter` 提供它们与 `dart:ui` 类型的互转（`window.bounds.toRect()`、`Offset(10, 20).toNative()`），并且不重新导出与 Flutter 重名的 nativeapi 名字（`Brightness`、`Color`、`Display`、`Image`、`ModifierKey`、`ShortcutManager`、`Size`）；需要写出这些类型时，给 `package:nativeapi/nativeapi.dart` 加 import 前缀。

## 快速开始

```dart
import 'package:nativeapi/nativeapi.dart';

for (final display in DisplayManager.instance.getAll()) {
  print('${display.name ?? ''}: ${display.size.width}x${display.size.height}');
}
```

### 自定义窗口标题栏

引入 `package:nativeapi_flutter/nativeapi_flutter.dart` 后，用 `DragToMoveArea` 包裹自定义标题栏即可拖动窗口（双击最大化/还原），用 `DragToResizeArea` 包裹窗口内容即可从边缘和四角调整大小：

```dart
DragToResizeArea(
  resizeEdgeSize: 8,
  child: Column(
    children: [
      DragToMoveArea(
        child: SizedBox(height: 40, child: Center(child: Text('My window'))),
      ),
      Expanded(child: MyContent()),
    ],
  ),
)
```

两个组件未传入 `window` 时使用 `WindowManager.instance.getCurrent()`。Linux 上暂不支持通过 `DragToMoveArea` 移动窗口。

### 用 Flutter 渲染的第二个窗口

`Window.create()` 打开的是一个不含 Flutter 视图的原生空窗口。要在第二个窗口里渲染 widget，请用 Flutter 的多窗口 API 创建窗口，再把 controller 交给 nativeapi：

```dart
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:nativeapi_flutter/nativeapi_flutter.dart';
import 'package:nativeapi_flutter/windowing.dart';

// 在 WidgetsFlutterBinding.ensureInitialized() 之前：stable 没有
// `flutter config --enable-windowing`，所以由应用自己打开这个开关。
isWindowingEnabled = true;

final controller = fw.RegularWindowController(
  size: const Size(320, 48),
  title: 'Toolbar',
);

// 在 widget 树中：fw.RegularWindow(controller: controller, child: ...)

final window = controller.nativeWindow; // nativeapi 的 Window，与 WindowManager 返回的 id 相同
window?.titleBarStyle = TitleBarStyle.hidden;
window?.isAlwaysOnTop = true;
```

所有窗口共用一个 engine 和一个 isolate，窗口之间直接通过普通 Dart 对象通信——不需要改 runner，也不需要消息通道。Flutter 的多窗口 API 仍是实验性的、属于框架内部接口，因此这个桥接单独放在 `package:nativeapi_flutter/windowing.dart` 里。它针对 **stable** channel 编写（已在 3.47.5 上验证）；stable 不提供 `flutter config --enable-windowing`，所以示例在 `main()` 里直接打开 Flutter 内部的 `isWindowingEnabled`。子窗口的完整例子见 [`floating_toolbar_example`](../../examples/flutter_floating_toolbar_example)，另见 [`browser_tabs_example`](../../examples/flutter_browser_tabs_example) 和 [`detachable_window_example`](../../examples/flutter_detachable_window_example)。

## 示例

示例是仓库 [`examples/`](../../examples) 下的 `flutter_*` 目录，每个目录是对应一个模块的 Flutter 应用，依赖通过仓库根目录的 pub workspace 解析：

```bash
flutter pub get          # 在仓库根目录执行
cd examples/flutter_display_example
flutter run
```

## 参与贡献

开发在 [nativeapi](https://github.com/libnativeapi/nativeapi) 中进行，它包含所有绑定和代码生成器，并以 submodule 的形式检出核心库：

```bash
git clone --recursive https://github.com/libnativeapi/nativeapi.git
```

标有 `AUTO-GENERATED. DO NOT EDIT.` 的文件由 [nativeapi](https://github.com/libnativeapi/nativeapi-core) 的 C++ 头文件生成。如需修改 API，请向该仓库提交 PR，绑定由维护者重新生成。

- API 需求、原生行为问题 → [nativeapi-core issues](https://github.com/libnativeapi/nativeapi-core/issues)
- 仅影响某个绑定的问题 → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)
- 不确定 → [nativeapi-core issues](https://github.com/libnativeapi/nativeapi-core/issues)

## 许可证

[MIT](./LICENSE)
