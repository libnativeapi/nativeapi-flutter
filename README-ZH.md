# nativeapi-flutter

[nativeapi](https://github.com/libnativeapi/nativeapi) 的 Flutter 绑定，统一访问原生系统 API：窗口、托盘图标、菜单、显示器、键盘、对话框、存储等。

| Android | iOS | Linux | macOS | Windows |
|:-------:|:---:|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

🚧 **开发中**：此包正在积极开发中。

[English](./README.md) | 简体中文

## 安装

```bash
flutter pub add nativeapi
```

## 快速开始

```dart
import 'package:nativeapi/nativeapi.dart';

for (final display in DisplayManager.instance.getAll()) {
  print('${display.name ?? ''}: ${display.size.width}x${display.size.height}');
}
```

### 自定义窗口标题栏

用 `DragToMoveArea` 包裹自定义标题栏即可拖动窗口（双击最大化/还原），用 `DragToResizeArea` 包裹窗口内容即可从边缘和四角调整大小：

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

> **暂未包含在 pub.dev 的包里。** `package:nativeapi/windowing.dart` 跟随 Flutter main 通道，在 stable 上无法通过分析，
> 所以 0.2.7 发布时没有带上它。要使用它，请改为依赖 [git 仓库](https://github.com/libnativeapi/nativeapi-flutter)。

`Window.create()` 打开的是一个不含 Flutter 视图的原生空窗口。要在第二个窗口里渲染 widget，请用 Flutter 的多窗口 API 创建窗口，再把 controller 交给 nativeapi：

```dart
import 'package:flutter/src/widgets/_window.dart' as fw;
import 'package:nativeapi/nativeapi.dart';
import 'package:nativeapi/windowing.dart';

final controller = fw.WindowController(
  size: const Size(320, 48),
  title: 'Toolbar',
);

// 在 widget 树中：fw.Window(controller: controller, child: ...)

final window = controller.nativeWindow; // nativeapi 的 Window，与 WindowManager 返回的 id 相同
window?.titleBarStyle = TitleBarStyle.hidden;
window?.isAlwaysOnTop = true;
```

所有窗口共用一个 engine 和一个 isolate，窗口之间直接通过普通 Dart 对象通信——不需要改 runner，也不需要消息通道。Flutter 的多窗口 API 仍是实验性的：需要 **main** channel 并执行 `flutter config --enable-windowing`，因此这个桥接单独放在 `package:nativeapi/windowing.dart` 里。子窗口的完整例子见 [`floating_toolbar_example`](examples/floating_toolbar_example)，另见 [`browser_tabs_example`](examples/browser_tabs_example) 和 [`detachable_window_example`](examples/detachable_window_example)。

## 示例

见 [`examples/`](examples)，每个目录是对应一个模块的 Flutter 应用：

```bash
flutter pub get
cd examples/display_example
flutter run
```

## 参与贡献

本仓库在 [workspace](https://github.com/libnativeapi/workspace) 中开发，它把核心库、所有绑定和代码生成器放在一起：

```bash
git clone --recursive https://github.com/libnativeapi/workspace.git
```

标有 `AUTO-GENERATED. DO NOT EDIT.` 的文件由 [nativeapi](https://github.com/libnativeapi/nativeapi) 的 C++ 头文件生成。如需修改 API，请向该仓库提交 PR，绑定由维护者重新生成。

- API 需求、原生行为问题 → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)
- 仅影响某个绑定的问题 → 对应绑定的仓库
- 不确定 → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)

## 许可证

[MIT](./LICENSE)
