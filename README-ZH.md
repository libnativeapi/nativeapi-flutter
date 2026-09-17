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
