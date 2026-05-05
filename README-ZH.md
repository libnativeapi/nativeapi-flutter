# nativeapi

[nativeapi](https://github.com/libnativeapi/libnativeapi) 的 Flutter 绑定 - 提供无缝、统一的原生系统 API 访问。

🚧 **开发中**: 此包目前正在积极开发中。

## 平台支持

| Android | iOS | Linux | macOS | Windows |
|:-------:|:---:|:-----:|:-----:|:-------:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

## 功能特性

- **窗口管理** — 创建、显示、隐藏、居中窗口；控制标题栏样式、视觉效果和控制按钮
- **托盘图标** — 系统托盘图标，支持菜单和右键菜单触发
- **多屏幕管理** — 枚举和查询多屏幕显示信息
- **菜单** — 原生菜单系统，支持事件回调
- **对话框** — 消息对话框及原生对话框 API
- **辅助功能** — 无障碍管理器 API
- **偏好设置** — 持久化键值存储
- **安全存储** — 加密键值存储
- **URL 打开器** — 使用系统默认浏览器/处理程序打开 URL
- **定位策略** — 灵活的窗口定位策略和位置支持
- **Widget** — `ContextMenuRegion` 右键菜单集成组件

## 快速开始

在 `pubspec.yaml` 中添加 `nativeapi`:

```yaml
dependencies:
  nativeapi: ^0.1.1
```

然后运行:

```bash
flutter pub get
```

## 使用方法

```dart
import 'package:nativeapi/nativeapi.dart';

// 窗口管理 - 获取当前窗口并进行操作
final windowManager = WindowManager.instance;
final window = windowManager.getCurrent();
window?.show();
window?.center();
window?.titleBarStyle = TitleBarStyle.hidden;

// 监听窗口事件
windowManager.addCallbackListener<WindowFocusedEvent>((event) {
  print('窗口获得焦点: ${event.windowId}');
});

// 托盘图标
final trayIcon = TrayIcon();
trayIcon.icon = Image.fromAsset('assets/tray_icon.png');
trayIcon.contextMenu = Menu();
trayIcon.contextMenuTrigger = ContextMenuTrigger.rightClicked;
trayIcon.on<TrayIconClickedEvent>((event) {
  print('托盘图标被点击');
});

// URL 打开器（同步调用）
final result = UrlOpener.instance.open('https://example.com');
print('打开结果: ${result.success}');

// 偏好设置（同步调用，使用完记得 dispose）
final prefs = Preferences();
prefs.set('theme', 'dark');
final theme = prefs.get('theme', 'light'); // 第二个参数为默认值
prefs.dispose();
```

> 📖 更详细的文档和示例即将推出。请查看 [`examples/`](https://github.com/libnativeapi/nativeapi-flutter/tree/main/examples) 目录中的示例应用。

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
