# 平台接缝规范：跨平台代码与平台代码的边界

> 状态：已实施（存量缺口见 §4.4）
> 适用范围：`core/src/*.h`、`core/src/platform/**`
> 核实基准：2026-08-25，25 个公共头中 14 个用 PIMPL

本规范回答：**平台相关的状态和代码，藏在哪里、怎么藏。**
目录与平台矩阵见 [architecture.md](architecture.md)。

## 1. 不可协商的一条

**公共头文件里不得出现任何平台类型、平台包含、平台宏分支。**

`HWND`、`NSWindow*`、`GtkWidget*`、`<windows.h>`、`#ifdef __APPLE__` 一律不进
`src/*.h`。违反这条，下游三个语言绑定和 codegen 的 libclang 解析全部要按平台重跑，
公共 API 也不再是单一定义。

接缝的全部意义就是维持这条。下面三种形态都合法，按**接缝宽度从窄到宽**排列，
优先选窄的。

## 2. 形态一：无平台代码（最优）

逻辑能完全用标准库和 foundation 表达时，不要开接缝。`shortcut.h`、`placement.h`、
`positioning_strategy.h`、`storage.h` 等属于此类。

## 3. 形态二：窄接缝——私有平台成员函数

类的主体逻辑写在共享 `.cpp` 里，只把**真正需要原生 API 的那一两个动作**声明为私有
成员函数，由各平台文件分别定义。

`DisplayManager` 是范本（`display_manager.h` / `display_manager.cpp`）：

```cpp
// display_manager.h —— 私有区
struct NativeDisplayInfo { std::string key; /* ... */ };

/// Enumerate the platform's current displays. Implemented per platform.
std::vector<NativeDisplayInfo> EnumerateNativeDisplays();

std::vector<std::shared_ptr<Display>> Reconcile(...);   // 共享
void HandleDisplaysChanged();                            // 共享
```

平台文件只实现 `EnumerateNativeDisplays()`；缓存、diff、事件发射三件事各平台完全
共用（`display_manager.cpp`）。

**什么时候选它**：平台差异集中在「取一份数据」或「触发一个动作」，其余是纯逻辑。
好处是 diff/缓存/事件这类最容易写出平台间行为不一致的代码只有一份。

**代价**：平台数据需要一个跨平台的中间结构体（这里是 `NativeDisplayInfo`），
它是私有实现细节，不得出现在公共 API 上。

## 4. 形态三：PIMPL——整体隐藏

类持有大量平台状态时，用 PIMPL 把整个实现搬走。当前 25 个公共头中 14 个如此。

```cpp
// 头文件：只前向声明
class Window {
 public:
  Window();
  Window(void* native_window);
  virtual ~Window();          // 必须声明，且定义在 .cpp
  void Show();

 private:
  class Impl;                 // 只声明，不定义
  std::unique_ptr<Impl> pimpl_;
};
```

```cpp
// platform/macos/window_macos.mm：定义 Impl
class Window::Impl {
 public:
  explicit Impl(NSWindow* window) : window_(window) {}
  NSWindow* window_;
};

Window::Window() : Window(nullptr) {}          // 委托，见 4.2
Window::~Window() = default;                   // 定义在 .cpp，不能在头里
void Window::Show() {
  if (!pimpl_->window_) return;                // 见 4.3
  [pimpl_->window_ makeKeyAndOrderFront:nil];
}
```

### 4.1 硬性规则

1. 内部类固定叫 `Impl`，成员固定叫 `pimpl_`，类型固定 `std::unique_ptr<Impl>`。
   `keyboard_monitor.h` 目前用的是 `impl_`（19 处成员里唯一的例外），属于待清理的
   不一致。
2. **析构函数必须在 `.cpp` 中定义**，哪怕 `= default`。写在头里时 `Impl` 还是不完全
   类型，`unique_ptr` 的删除器实例化失败。
3. 头文件不含任何平台包含——这是第 1 节的直接推论。
4. 平台状态一律经 `pimpl_->` 访问；平台成员不出现在类的私有区。

### 4.2 多构造函数一律委托

默认构造委托给带原生对象的构造，「新建」与「包装既有对象」两条路径的初始化只写一遍：

```cpp
TrayIcon::TrayIcon() : TrayIcon(nullptr) {}

TrayIcon::TrayIcon(void* tray) {
  NSStatusItem* item = tray
      ? (__bridge NSStatusItem*)tray
      : [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  pimpl_ = std::make_unique<Impl>(item);
  // 两种来源共用的后续配置只此一处
}
```

不委托就意味着同一段初始化写两遍，两份迟早分叉。

### 4.3 原生句柄一律先判空

平台对象可能已经销毁（窗口被关、显示器被拔）。每个转发方法开头判空后早返回；
getter 在句柄为空时返回类型默认值。这条是 [object-model.md](object-model.md)
「属性活读」规则在平台层的落点。

### 4.4 存量缺口

- **状态成员裸露在公共头**（应全部下沉 `Impl`）：`Application`（`initialized_` /
  `running_` / `exit_code_` / `primary_window_`）、`TrayManager`（`trays_` /
  `next_tray_id_` / `mutex_`）、`ShortcutManager`（两个 map + mutex + `enabled_`）、
  `MessageDialog`（`modality_`）、`WindowDragSession`（5 个状态成员）、
  `AccessibilityManager`（`enabled_`，文档声称线程安全但无任何同步）。
- **public 抽象 `Impl`**：`ShortcutManager`、`UrlOpener`、`AppInfo`、`DeviceInfo` 把纯虚
  `Impl` 开在 public 区，由平台工厂返回派生类。它不属于本篇任何一种形态，实现接口因此
  漏进公共头。新模块不要复制；要么收敛回私有 PIMPL，要么在这里正式立为第四种形态。
- `KeyboardMonitor` 的成员叫 `impl_`（见 4.1）。

## 5. 反方向：`NativeObjectProvider`

接缝把平台类型挡在里面；`NativeObjectProvider` 是**唯一**受控的向外出口，让高级
调用方拿到原生句柄去做库没封装的事。

```cpp
class Window : public NativeObjectProvider, public std::enable_shared_from_this<Window> {
 protected:
  void* GetNativeObjectInternal() const override { return pimpl_->window_; }
};
```

- 公开的 `GetNativeObject()` 是非虚的，虚的是受保护的 `GetNativeObjectInternal()`。
  派生类只实现后者。
- 返回 `void*` 而非模板：模板会把平台类型拖回公共头，与第 1 节冲突。类型正确性由
  调用方按平台自行 `static_cast` / `__bridge` 保证。
- 当前实现者 6 个：`Window`、`Display`、`Image`、`Menu`、`MenuItem`、`TrayIcon`。
- **所有权不随句柄转移。** 调用方不得 `delete` / `release` / `CloseHandle` 拿到的
  对象，其生命周期仍由 C++ 包装对象管。句柄只在包装对象存活期间有效。
- 底层对象已销毁时返回 `nullptr`；调用方必须判空。

## 6. 平台文件组织

- 文件名 `<模块>_<平台>.<ext>`，与接口层头文件同名前缀（`window.h` →
  `window_windows.cpp` / `window_macos.mm` / `window_linux.cpp` / …）。
- 一个平台文件只服务一个模块，不跨模块塞代码。
- 平台专属的公共辅助放同目录（`windows/string_utils_windows.h`、
  `macos/coordinate_utils_macos.h`），不上提到 `foundation/`。

### 6.1 Windows 头文件顺序

`<windows.h>` 必须先于依赖它的 Win32 头（`<shellapi.h>` 等），而 clang-format 会按
字母序重排，把顺序打乱成编译错误。用格式化开关圈住这一组：

```cpp
// clang-format off
#include <windows.h>
#include <shellapi.h>
// clang-format on
#include <functional>
#include <memory>
```

只圈需要固定顺序的那几行，其余包含照常参与排序。当前 22 个 windows 平台文件中 3 个
需要这样处理。

## 7. 检查单

- [ ] 先问：能不做平台代码吗（形态二）？能只做一个函数吗（形态三）？
- [ ] 公共头零平台类型、零平台包含、零 `#ifdef` 平台分支。
- [ ] 用 PIMPL：`Impl` / `pimpl_` / `unique_ptr` 三件套齐全，析构定义在 `.cpp`。
- [ ] 多构造函数已委托到同一个。
- [ ] 每个转发方法开头判空原生句柄。
- [ ] 需要暴露原生对象：继承 `NativeObjectProvider`，只重写
      `GetNativeObjectInternal()`，并在文档里写明各平台的实际类型。
- [ ] 六个平台目录都有对应文件（[architecture.md](architecture.md) §2.1）。
