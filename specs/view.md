# View 规范：统一的原生控件 API

> 状态：**已实施**（core 2026-09-25：`View` / `Label` / `Button` / `TextField` / `ImageView`，
>   Absolute + Row / Column 布局，`Window::GetContentView()`；macOS 在真机上跑过
>   三个桌面平台都跑过真机 GUI 测试，见 §9）
> 适用范围：`core/src/view.h`、`core/src/window.h` 的 `GetContentView`、
>   `foundation/geometry.h` 的 `EdgeInsets`、`foundation/id_allocator.h` 的 tag 20–24、
>   `foundation/handle_table.h` 的基类链、六个平台目录的 `view_*` 文件、codegen 的类继承支持
> 核实基准：2026-09-25，对照 core `src/` 与 `tools/codegen`

本规范回答：**不用 Flutter / GPUI / WebView，只靠 nativeapi，怎么在一个窗口里放几个
原生控件并响应它们**——一个设置面板、一个登录框、一条带按钮的工具栏、一个状态标签。
它不是 UI 框架：没有样式系统、没有动画、没有绘图 API。目标用户是从 Python / Deno /
Rust / C# 直接调库、想要「一个按钮、一个输入框、一个回调」的人。

## 1. 决策一览

| 问题 | 决定 | 依据 |
|---|---|---|
| 类型模型 | `View` 是具体的容器基类，`Label` / `Button` / `TextField` … 各是一个派生类，只带自己的方法 | 类型安全，`Button` 上没有 `SetChecked`；绑定里是自然的 `class Button extends View`。codegen 要学会继承（§8） |
| 归属 | 身份对象：`shared_ptr`、`ViewId`、每个类一个 `IdTypeTag` | 包装唯一的 `NSView` / `HWND` / `GtkWidget`（[object-model.md](object-model.md) §2） |
| 谁持有 | 父 View 强持子 View；子 View 弱引用父；`Window` 持根 View | 树形所有权，没有 manager、没有 registry（§4） |
| 事件 | `View` 是 `EventEmitter<ViewEvent>`；基类存 `ViewId`；派生类只发自己领域的子事件 | 对象级事件挂对象（[event-system.md](event-system.md) §6） |
| 布局 | 绝对坐标 + 由 core 共享代码计算的 Row / Column 栈式布局 | 平台只做「建控件、摆位置、读固有尺寸」，布局算法只有一份（[platform-seam.md](platform-seam.md) §3） |
| 坐标 | 逻辑点，原点在**父 View 左上角**，y 向下 | 与 `Window::SetBounds` 一致；macOS 由平台层翻转 |
| 挂到窗口 | `Window::GetContentView()` 返回根 View，往里 `AddSubview` | 不新增「把 View 塞进窗口」的第二条路径 |
| 线程 | 只在主线程调用；事件同步 `Emit` | 与 `Window` 相同 |
| 失败表达 | 纯状态 setter 返回 `void`；只有 `IsSupported()` 和 `RemoveSubview*` 返回 `bool` | [api-style.md](api-style.md) §4 |
| 移动端 | Android / iOS / OHOS `IsSupported()` 返回 false，所有方法为 no-op | 桌面优先；接口层保持六平台都有符号 |

## 2. 用法

```cpp
auto window = std::make_shared<Window>();
window->SetTitle("Sign in");
window->SetContentSize({360, 200});

auto root = window->GetContentView();
root->SetLayout(ViewLayout::Column);
root->SetPadding(EdgeInsets::All(16));
root->SetSpacing(8);

auto name = std::make_shared<TextField>();
name->SetPlaceholder("Username");

auto password = std::make_shared<TextField>();
password->SetPlaceholder("Password");
password->SetSecure(true);

auto status = std::make_shared<Label>();
status->SetTextColor(Color::FromRGBA(136, 136, 136, 255));

auto button = std::make_shared<Button>("Sign in");
auto sign_in = [=](const ViewEvent&) {
  status->SetText("Signing in as " + name->GetText() + "...");
};
button->AddListener<ButtonClickedEvent>(sign_in);
password->AddListener<TextFieldSubmittedEvent>(sign_in);

root->AddSubview(name);
root->AddSubview(password);
root->AddSubview(status);
root->AddSubview(button);
window->Show();
Application::GetInstance().Run();
```

同一段在 Python 绑定里长这样（生成后的形态，由 codegen 决定，不手写）：

```python
root = window.content_view
root.layout = ViewLayout.COLUMN
button = Button("Sign in")
button.add_listener(lambda e: status.set_text(f"Signing in as {name.text}..."))
root.add_subview(button)          # Button 是 View，直接传
```

## 3. 类型

### 3.1 类族

```
View                      具体类：无外观的容器，唯一能有子 View 的类型
├── Label                 只读文本
├── Button                按钮
├── TextField             单行 / 多行 / 密码输入
└── ImageView             显示一张 Image
```

| 类 | 自己的方法 | 自己的事件 | macOS | Windows | Linux (GTK 3) |
|---|---|---|---|---|---|
| `View` | 树、几何、布局、可见 / 启用 / 背景 / tooltip / 焦点（§6） | `ViewFocusedEvent`、`ViewBlurredEvent` | 翻转坐标的 `NSView` 子类 | 注册一个窗口类的子 `HWND` | `GtkFixed` |
| `Label` | `Text`、`TextColor`、`FontSize`、`TextAlignment` | — | 不可编辑 `NSTextField` | `STATIC` | `GtkLabel` |
| `Button` | `Text` | `ButtonClickedEvent` | `NSButton`（push） | `BUTTON` / `BS_PUSHBUTTON` | `GtkButton` |
| `TextField` | `Text`、`TextColor`、`FontSize`、`TextAlignment`、`Placeholder`、`Editable`、`Secure`、`Multiline` | `TextFieldChangedEvent`、`TextFieldSubmittedEvent` | `NSTextField` / `NSSecureTextField` / `NSTextView` | `EDIT` | `GtkEntry` / `GtkTextView` |
| `ImageView` | `Image` | — | `NSImageView` | `STATIC` / `SS_BITMAP` | `GtkImage` |

命名说明：

- 叫 `ImageView` 不叫 `Image`，因为 `Image` 已是位图类；`TextField`、`Label` 取自
  [api-style.md](api-style.md) §1.7 的来源（Flutter / Electron 用户熟悉的词），不用
  `NSTextField` / `STATIC` 这类平台词。
- `Text*` 四个属性在 `Label`、`TextField`、`Button` 上按需重复声明，**不抽一个
  `TextView` 中间基类**：中间抽象层会让 codegen 的继承扁平化多一级，而三个类共享的只是
  声明，实现本来就各自不同。`Button` 只有 `Text`。
- 事件以派生类名为前缀（`ButtonClickedEvent`），不是 `ViewClickedEvent`：事件跟着能发它
  的类走，`AddListener<ButtonClickedEvent>` 只在 `Button` 上有意义。全部继承
  `ViewEvent`，基类存 `ViewId`，所以监听 `ViewEvent` 仍能收到一切。
- **不进 v1** 的类（`Checkbox`、`Dropdown`、`Slider`、`ProgressBar`、`Separator`、`Switch`、
  `RadioGroup`、`WebView`、`Table`）见 §9。

### 3.2 `ViewLayout`、`ViewAlignment`、`TextAlignment`

```cpp
/** How a View places its subviews. */
enum class ViewLayout {
  Absolute,   ///< Subviews keep the frame given by SetFrame(). The default.
  Row,        ///< Left to right; SetSpacing() between, SetPadding() around.
  Column      ///< Top to bottom; same knobs.
};

/** Cross-axis placement of a subview inside a Row or Column. */
enum class ViewAlignment { Stretch, Start, Center, End };

/** Horizontal placement of text inside a Label or TextField. */
enum class TextAlignment { Start, Center, End };
```

### 3.3 `EdgeInsets`（值对象）

```cpp
struct EdgeInsets {
  double top;
  double right;
  double bottom;
  double left;
  static EdgeInsets All(double value);
  static EdgeInsets Symmetric(double vertical, double horizontal);
};
```

放在 `foundation/geometry.h`：它是纯几何，`Rectangle` 的近亲，codegen 已把该头的
struct 平面映射到 C struct。

## 4. 所有权与生命周期

```
Window ──shared_ptr──▶ root View (包装窗口内容区)
                          │ shared_ptr（subviews_ 向量，有序）
                          ▼
                       child View / Button / … ──weak_ptr──▶ parent
```

1. `AddSubview` 后父强持子；`RemoveSubview` 只是从向量里摘掉，调用方仍持有的
   `shared_ptr` 让它继续活着，可再 `AddSubview` 到别处（先从旧父移除，与 `NSView`
   语义一致）。
2. 一个 View 同时只能有一个父。`AddSubview` 一个已有父的 View 等于先 `RemoveSubview`。
3. 原生控件由 `View::Impl` 持有（macOS `retain`，Windows `DestroyWindow` 于析构，GTK
   `g_object_ref_sink`）。**包装对象析构即销毁原生控件**——与 `Window` 不同，View
   不存在「同一原生对象多个包装」的问题，因为除根 View 外全部由本库创建。
4. 根 View 是例外：它包装的是窗口已有的内容区（macOS `contentView`、Windows 窗口
   `HWND` 自身、GTK 窗口的 child），由 `Window` 懒创建并缓存，**析构不销毁**原生对象。
   `GetContentView()` 每次返回同一实例（[object-model.md](object-model.md) §2 规则 3）。
5. 没有 `ViewManager`、没有 `ViewRegistry`。事件负载里的 `ViewId` 只用于在一个
   监听器里分辨多个来源；需要按 id 找对象的调用方自己存映射。要出现第二个
   「按 id 查」的需求再复用 `ObjectRegistry`，不预先建表。
6. `ViewId` 是整个类族共用的一种 ID（`IdAllocator::Allocate<View>()`，派生类不另分配）；
   但 `IdTypeTag` 每个具体类各一个（20–24，`View` = 20），因为句柄表按**动态类型**打 tag
   （[handle-ownership.md](handle-ownership.md) §2.2），上转型见 §8。
7. 派生类不各自开 PIMPL：状态全在原生控件上活读，`View::Impl` 持的那个原生句柄够用。
   派生类的平台实现是同一个 `view_<os>` 文件里的自由函数组，与 `menu_macos.mm` 同时
   实现 `Menu` 和 `MenuItem` 的做法一样——一个模块，六个文件，不因类多而翻倍。

### 4.1 宿主窗口是 Flutter / 其他框架时

`GetContentView()` 包装的就是宿主的内容视图，`AddSubview` 的控件**覆盖在**宿主内容之上
（macOS 上是同级 `NSView`，Windows 上是子 `HWND`，鼠标由最上层控件收到）。这是刻意
允许的——一个 Flutter 应用可以借此放一个原生输入框——但布局只管本库创建的子 View，
不动宿主视图的 frame。

## 5. 布局

布局算法全部在 `view.cpp`（共享代码）里，平台层提供三件事：设 frame、读固有尺寸、
在根 View 尺寸变化时回调。

- **Absolute**：子 View 的 frame 就是 `SetFrame()` 给的值，没给的是 `{0,0,固有尺寸}`。
- **Row / Column**：主轴上先给每个子 View 它的 `GetPreferredSize()`（没设就用平台的
  固有尺寸：`sizeThatFits` / `GetTextExtent` / `gtk_widget_get_preferred_size`），
  剩余空间按 `SetFlex()` 的权重分给 flex > 0 的子 View；交叉轴按 `SetAlignment()`，
  默认 `Stretch`。`SetSpacing()` 是相邻间距，`SetPadding()` 是容器内边距。
- **容器的固有尺寸是它的内容**：Row / Column 容器的 `GetIntrinsicSize()` 是它的可见子
  View 按各自首选（或固有）尺寸排开所需的大小——主轴首尾相接加间距，交叉轴取最大，
  再加内边距；flex 子 View 也按自然尺寸计入。所以嵌套的行列不设 `SetPreferredSize()`
  也不会塌成 0。Absolute 容器的固有尺寸是 0（子 View 自己定位）。
- 布局是**同步的**：任何影响布局的 setter（增删子 View、`SetFrame`、`SetPreferredSize`、
  `SetFlex`、`SetVisible`、固有尺寸型控件的 `SetText`）都在返回前重排该容器及其祖先。
  简单实现优先；发现性能问题再引入延迟到下一轮主循环的 dirty 标记。
- `SetVisible(false)` 的子 View 不占位（等价 Flutter 的 `Visibility` 而非 `Opacity`）。
- 根 View 的尺寸随窗口内容区变化（macOS `NSViewFrameDidChangeNotification`、Windows
  `WM_SIZE`、GTK `size-allocate`）；变化后重排一次。
- 不做：约束求解、文本换行驱动的高度、百分比。这些属于 UI 框架。

## 6. `view.h` 的形状

以 `core/src/view.h` 为准；下面是去掉注释的骨架，按 [api-style.md](api-style.md) §3.3 排列。
一个头放整个类族（同 `menu.h`，理由见 §7.1）。

```cpp
#pragma once

#include <memory>
#include <optional>
#include <string>
#include <vector>
#include "foundation/color.h"
#include "foundation/event.h"
#include "foundation/event_emitter.h"
#include "foundation/geometry.h"
#include "foundation/id_allocator.h"
#include "foundation/native_object_provider.h"

namespace nativeapi {

class Image;
class Window;

typedef IdAllocator::IdType ViewId;

enum class ViewLayout { Absolute, Row, Column };
enum class ViewAlignment { Stretch, Start, Center, End };
enum class TextAlignment { Start, Center, End };

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/** Base class for every view event. Carries the id of the view it concerns. */
class ViewEvent : public Event {
 public:
  explicit ViewEvent(ViewId view_id) : view_id_(view_id) {}
  ViewId GetViewId() const { return view_id_; }
  std::string GetTypeName() const override { return "ViewEvent"; }
 private:
  ViewId view_id_;
};

class ViewFocusedEvent : public ViewEvent {
 public:
  explicit ViewFocusedEvent(ViewId view_id) : ViewEvent(view_id) {}
  std::string GetTypeName() const override { return "ViewFocusedEvent"; }
};

class ViewBlurredEvent : public ViewEvent {
 public:
  explicit ViewBlurredEvent(ViewId view_id) : ViewEvent(view_id) {}
  std::string GetTypeName() const override { return "ViewBlurredEvent"; }
};

/** A Button was activated by mouse or keyboard. */
class ButtonClickedEvent : public ViewEvent {
 public:
  explicit ButtonClickedEvent(ViewId view_id) : ViewEvent(view_id) {}
  std::string GetTypeName() const override { return "ButtonClickedEvent"; }
};

/** The text of a TextField changed through user input. */
class TextFieldChangedEvent : public ViewEvent {
 public:
  TextFieldChangedEvent(ViewId view_id, std::string text)
      : ViewEvent(view_id), text_(std::move(text)) {}
  std::string GetText() const { return text_; }
  std::string GetTypeName() const override { return "TextFieldChangedEvent"; }
 private:
  std::string text_;
};

/** Enter was pressed in a single-line TextField. */
class TextFieldSubmittedEvent : public ViewEvent {
 public:
  explicit TextFieldSubmittedEvent(ViewId view_id) : ViewEvent(view_id) {}
  std::string GetTypeName() const override { return "TextFieldSubmittedEvent"; }
};

// ---------------------------------------------------------------------------
// View: the container and the base of every control
// ---------------------------------------------------------------------------

/**
 * @brief A rectangle inside a window that can hold other views.
 *
 * View on its own is a plain container. The controls derive from it and add
 * their own methods; everything here — the subview tree, geometry, layout,
 * visibility, focus — applies to all of them.
 *
 * Coordinates are logical points with the origin at the parent's top-left
 * corner and y growing downwards. Every method must be called on the main
 * thread. Events are emitted synchronously from the platform callback.
 *
 * @note Platform availability:
 * - macOS: ✅ Fully supported - AppKit views and controls
 * - Windows: ✅ Fully supported - Win32 common controls (classic theme)
 * - Linux: ✅ Fully supported - GTK 3 widgets
 * - Android: ❌ Not applicable - IsSupported() is false, every call is ignored
 * - iOS: ❌ Not applicable - IsSupported() is false, every call is ignored
 * - OpenHarmony: ❌ Not applicable - IsSupported() is false, every call is ignored
 */
class View : public EventEmitter<ViewEvent>,
             public NativeObjectProvider,
             public std::enable_shared_from_this<View> {
 public:
  static bool IsSupported();

  View();
  /** Wraps an existing NSView* / HWND / GtkWidget*. Used for a window's root view. */
  explicit View(void* native_view);
  virtual ~View();

  View(const View&) = delete;
  View& operator=(const View&) = delete;
  View(View&&) = delete;
  View& operator=(View&&) = delete;

  ViewId GetId() const;

  // === Tree ===
  void AddSubview(std::shared_ptr<View> view);
  void InsertSubview(size_t index, std::shared_ptr<View> view);
  bool RemoveSubview(std::shared_ptr<View> view);
  bool RemoveSubviewAt(size_t index);
  void ClearSubviews();
  size_t GetSubviewCount() const;
  std::shared_ptr<View> GetSubviewAt(size_t index) const;
  std::vector<std::shared_ptr<View>> GetSubviews() const;
  /** nullptr for a root view or a view not yet added anywhere. */
  std::shared_ptr<View> GetParent() const;
  /** The window this view is currently inside, nullptr while detached. */
  std::shared_ptr<Window> GetWindow() const;

  // === Geometry & layout ===
  /** Relative to the parent's top-left corner. Overwritten by a Row/Column parent. */
  void SetFrame(Rectangle frame);
  Rectangle GetFrame() const;
  /** Main-axis size hint for Row/Column; zero means "use the intrinsic size". */
  void SetPreferredSize(Size size);
  Size GetPreferredSize() const;
  /** What the control wants to be; read from the platform. */
  Size GetIntrinsicSize() const;
  /** Share of leftover main-axis space in a Row/Column parent. 0 = fixed. */
  void SetFlex(double flex);
  double GetFlex() const;
  void SetAlignment(ViewAlignment alignment);
  ViewAlignment GetAlignment() const;
  void SetLayout(ViewLayout layout);
  ViewLayout GetLayout() const;
  void SetSpacing(double spacing);
  double GetSpacing() const;
  void SetPadding(EdgeInsets padding);
  EdgeInsets GetPadding() const;

  // === Appearance & state ===
  void SetVisible(bool is_visible);
  bool IsVisible() const;
  void SetEnabled(bool is_enabled);
  bool IsEnabled() const;
  /**
   * @note Platform availability:
   * - macOS: ✅ Fully supported - layer background
   * - Windows: ⚠️ View and Label only - other controls keep the theme colour
   * - Linux: ⚠️ Applied through a CSS provider; themes may override it
   */
  void SetBackgroundColor(Color color);
  Color GetBackgroundColor() const;
  void SetTooltip(const std::optional<std::string>& tooltip);
  std::optional<std::string> GetTooltip() const;
  void Focus();
  void Blur();
  bool IsFocused() const;

 protected:
  /** For the controls: wraps the native control a derived constructor created. */
  struct NativeControl;   // opaque token so derived constructors cannot pass arbitrary pointers
  explicit View(NativeControl control);

  void StartEventListening() override;
  void StopEventListening() override;
  void* GetNativeObjectInternal() const override;

 private:
  class Impl;
  std::unique_ptr<Impl> pimpl_;
};

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------

/** Read-only text. */
class Label : public View {
 public:
  explicit Label(const std::string& text = "");
  virtual ~Label();

  void SetText(const std::string& text);
  std::string GetText() const;
  void SetTextColor(Color color);
  Color GetTextColor() const;
  /** 0 restores the platform default size. */
  void SetFontSize(double size);
  double GetFontSize() const;
  void SetTextAlignment(TextAlignment alignment);
  TextAlignment GetTextAlignment() const;
};

/** A push button. Emits ButtonClickedEvent. */
class Button : public View {
 public:
  explicit Button(const std::string& text = "");
  virtual ~Button();

  void SetText(const std::string& text);
  std::string GetText() const;
};

/** Text entry. Emits TextFieldChangedEvent and TextFieldSubmittedEvent. */
class TextField : public View {
 public:
  explicit TextField(const std::string& text = "");
  virtual ~TextField();

  void SetText(const std::string& text);
  std::string GetText() const;
  void SetTextColor(Color color);
  Color GetTextColor() const;
  void SetFontSize(double size);
  double GetFontSize() const;
  void SetTextAlignment(TextAlignment alignment);
  TextAlignment GetTextAlignment() const;
  void SetPlaceholder(const std::optional<std::string>& placeholder);
  std::optional<std::string> GetPlaceholder() const;
  void SetEditable(bool is_editable);
  bool IsEditable() const;
  /** Password entry: glyphs are masked. */
  void SetSecure(bool is_secure);
  bool IsSecure() const;
  /** Multi-line text; Enter inserts a newline instead of emitting TextFieldSubmittedEvent. */
  void SetMultiline(bool is_multiline);
  bool IsMultiline() const;
};

/** Shows an Image, scaled to fit while keeping its aspect ratio. */
class ImageView : public View {
 public:
  ImageView();
  virtual ~ImageView();

  void SetImage(std::shared_ptr<Image> image);
  std::shared_ptr<Image> GetImage() const;
};

}  // namespace nativeapi
```

`window.h` 加一处：

```cpp
  // === Content view ===
  /**
   * @brief The view filling the window's content area.
   *
   * Created on first call and cached; the same instance is returned for the
   * life of the window. It wraps the window's existing content view (a
   * Flutter or GPUI view when a host framework owns the window), so subviews
   * added to it sit on top of that content. The root's frame follows the
   * content area; SetFrame() on it is ignored.
   * @return nullptr when View::IsSupported() is false.
   */
  std::shared_ptr<View> GetContentView() const;
```

### 6.1 逐条对照 api-style 检查单

- 名字：`Focus`/`Blur`/`IsFocused`、`SetEnabled`/`IsEnabled`、`SetVisible`/`IsVisible`
  取自 §1.2 的固定对子；`SetVisible` 而非 `Show`/`Hide` 是因为 View 不是窗口类对象，
  跟 `TrayIcon`。集合方法照 §1.3 的 `Menu` 范本换名词（`Subview`）。
- 没有重载；派生类各一个带默认实参的构造函数（`Label("")`）是 §1.6 允许的便利形态。
- 所有 getter `const`，setter / getter 相邻，布尔参数 `is_` 前缀。
- 类型都在 §2 表内：`Color` / `Rectangle` / `Size` / `EdgeInsets` 按值，`optional` 只包
  字符串且 get/set 对称，`vector<string>` 入参 `const&`，身份对象只以 `shared_ptr` 进出。
- `SetMinimumValue` / `SetMaximumValue` 拆成两个方法而不是 `SetRange(min, max)`：
  §1.1 要求 setter 单值、getter 成对，多值就得再造一个 struct。
- 事件 getter 带领域词：`GetViewId()`。事件类名以派生类为前缀（§3.1）。
- `View` 的受保护构造用一个不透明 token 类型 `NativeControl`，不用 `void*`：public 的
  `View(void*)` 是给根 View 的，派生类不该拿到「随便包一个指针」的能力；token 定义在
  `view.cpp` 内部。
- `GetContentView() const` 懒创建：`Menu::GetSubmenu() const` 是同形先例，缓存放
  `pimpl_`。
- `enable_shared_from_this<View>`：`GetParent()` / `GetWindow()` 需要它，`Window` 已有
  同样的基类。

## 7. 代码放哪、平台实现要点

### 7.1 文件布局

一个公共头、一个绑定模块；桌面平台的实现先合并成两个文件，长大再拆：

```
src/view.h                          公共头：ViewEvent 家族、View 和四个控件
src/view.cpp                        共享：子 View 树、ViewId、根 View 缓存、事件转发
src/view_layout.h / view_layout.cpp 私有：Row / Column 布局算法，纯函数，可单测
src/platform/<os>/view_<os>.<ext>            View 基类：建容器、frame、可见 / 启用 / 焦点、
                                             根 View 包装、尺寸变化回调
src/platform/<os>/view_controls_<os>.<ext>   四个控件的构造、属性、事件挂钩
src/platform/<os>/view_internal_<os>.h       两个平台文件共享的 Impl 定义、建控件、
                                             字体、文本属性、事件登记的 helper
```

Android / iOS / OHOS 各只要一个 `view_<os>` 桩，所有类的桩写在一起。

为什么这样切：

- **不开 `src/view/` 子目录**：`src/CMakeLists.txt` 的 glob 是平的（`*.cpp`、
  `platform/<os>/*.mm`），[architecture.md](architecture.md) 也规定公共头平铺。
- **不按类拆头**：codegen 一个头对应一个 C 模块、一个绑定模块（`menu.h` 装两个类，
  绑定里就是一个 `menu` 模块）。拆成 5 个头，Python / Rust 就多 5 个模块，
  `image_view.py` 没有意义。
- **控件先合并在一个平台文件里**：一个模块多个平台文件有先例（`menu_windows.cpp` +
  `menu_winui3_windows.cpp`），`src/` 里的私有头有 `drag_source_impl.h` 先例。
  四个控件预估 macOS / Linux 约 500 行、Windows 约 800 行（窗口类注册、`WM_COMMAND`
  分发、字体与 DPI）。**拆分触发条件**：某平台的 `view_controls_<os>` 超过 `menu_windows.cpp`
  的规模（约 1100 行），或 §9 的后续控件加进来时，改为每控件一个文件
  `view_<control>_<os>.<ext>`，`view_internal_<os>.h` 不变。
- 三个带文本的控件共用 `view_internal_<os>.h` 里的文本 / 字体 helper，头文件里的
  重复声明不带来重复实现。
- 何时该拆头：某个控件长出自己的一族事件和子类型（比如以后的 `Table` 带列、行、
  选择事件）时单独成 `table.h`，与 `View` 的关系走 §8 的基类链。

### 7.2 平台实现要点

| | macOS | Windows | Linux |
|---|---|---|---|
| 坐标翻转 | 容器是 `isFlipped = YES` 的 `NSView` 子类；根 View 若包装的是非翻转视图，在设 frame 时按父高度翻转 y | 原生就是左上原点 | `GtkFixed` 左上原点 |
| DPI | 逻辑点原生 | frame 乘窗口 DPI（复用 `dpi_utils_windows`） | 逻辑点原生 |
| 事件挂钩 | target/action，`NSTextFieldDelegate`、`NSNotification` | 父 `HWND` 的 `WM_COMMAND` / `WM_NOTIFY` / `WM_HSCROLL`，经 `WindowMessageDispatcher` 按控件 `HWND` 分发 | `g_signal_connect` |
| 惰性监听 | `StartEventListening` 才设 delegate | 才注册分发条目 | 才 connect |
| 固有尺寸 | `fittingSize` / `sizeThatFits:` | `GetTextExtentPoint32` + 主题 metrics；`BCM_GETIDEALSIZE` | `gtk_widget_get_preferred_size` |
| 字体 | `NSFont systemFontOfSize:` | `CreateFontIndirect` 自系统消息字体 | Pango 属性 |
| 主题 | 自动 | 经典 common controls；深色由 `application_theme_windows` 后续接（v1 ⚠️） | 跟 GTK 主题 |
| 根 View 尺寸变化 | `NSViewFrameDidChangeNotification` | 窗口的 `WM_SIZE`，已由 `window_windows.cpp` 收到 | `size-allocate` |

### 7.3 Windows 的 WinUI 3 后端

按 `MenuBackend` 的先例：`NATIVEAPI_ENABLE_WINUI3` 编译进来时默认用 WinUI 3。
公共 API 是 `ViewBackend { Native, WinUI3 }` 加三个静态方法和一个 getter：

- `IsBackendSupported(ViewBackend)`：编译期能力。
- `SetDefaultBackend(ViewBackend)` / `GetDefaultBackend()`：之后新建的视图用哪个，
  进程级；不支持的返回 `false`。
- `GetBackend() const`：这个视图创建时定下的后端，之后不变。

为什么是「创建时定死、进程级默认」而不是 `Menu` 那样的实例级 `SetBackend`：控件的原生
对象在构造函数里就建好了（HWND 或 XAML 元素），一棵树里也不能混两种——XAML 元素进不了
HWND 容器，反之亦然。所以 `InsertSubview` 在共享代码里直接拒绝后端不同的子视图。

实现在 `platform/windows/view_winui3_windows.{h,cpp}`（只在开关打开时编译），Win32 的
每个接缝函数和控件方法开头一行 `NATIVEAPI_VIEW_XAML(...)` 转发。根视图是覆盖整个客户区
的 `DesktopWindowXamlSource`，里面一个 `Canvas`；容器是 `Canvas`，子视图靠
`Canvas.Left/Top` 和 `Width/Height` 摆放，单位是有效像素，正好是共享布局用的逻辑点。
细节与限制见 core 的 `docs/winui3.md`。

## 8. codegen 与 C ABI：继承怎么过桥

设计时的方案是每个派生类生成一个 `native_button_as_view()` 上转型函数。落地时改成了
**句柄表认识基类链**，不需要任何上转型函数，绑定里也不用维护两个句柄：

1. **`IdTypeTag<T>` 可以声明 `using Base = View;`**（`id_allocator.h`）。
   `HandleTypeChain<T>` 在编译期把 tag 链（自身 → 各级基类）算出来。
2. **句柄表每个槽位存整条 tag 链**（`handle_table.h`，最多 4 层）。`Insert<Button>`
   存的是转成链根类型（`View`）的指针；`Resolve<View>(button_handle)` 只要链上有 `View`
   的 tag 就通过，再从根静态转回 `View`。反向（`Resolve<Button>(view_handle)`）照旧拒绝，
   无关类型照旧拒绝。`tests/handle_table_test.cpp` 有对应用例。
3. **C ABI 因此不变形**：`native_button_t` 可以直接传给任何 `native_view_*` 函数，包括
   `native_view_add_listener`；`view_c.h` 里的注释写明了这点。派生类只生成自己的方法、
   构造和 `_free`。
4. **IR** 的 `Class` 多了 `base: Option<String>`：只记录同为导出类的直接基类
   （`EventEmitter<…>`、`NativeObjectProvider`、`enable_shared_from_this` 不算），
   在 `parse()` 末尾用导出类清单过滤，所以 `Preferences : Storage`、
   `MessageDialog : Dialog` 仍是独立类。
5. **五个绑定**都生成真正的继承：Dart `class Button extends View`（构造转发
   `super.fromHandle`）、JS `extends View`、Python `class Button(View)`、
   C# `partial class Button : View`（`View` 不再 `sealed`）、Rust
   `#[repr(transparent)]` + `impl Deref<Target = View>` + `AsRef<View>`。
   基类的方法和监听器一律继承，不重复生成。
6. 顺带解决的两件事：
   - **C 头文件互相引用**（`view_c.h` ↔ `window_c.h`）：每个生成的 C 头在 `#include`
     其他模块之前，先 `typedef uint64_t native_xxx_t;` 前置声明它用到的外部句柄。
   - **默认实参**：IR 的 `Param` 记录 `has_default`；JS 生成器把它变成 TypeScript 默认
     参数（`create(text = "")`），既贴近 C++ 的调用形态，也让派生类的静态 `create`
     与基类的兼容（TypeScript 检查 `extends` 的静态侧）。
7. **Dart 的事件类名保持 C++ 原名**：以前按「组名 + 判别词」拼，`KeyPressedEvent` 会变成
   `KeyboardKeyPressedEvent`；现在五个绑定的事件名一致。这是 Dart 包的一处破坏性改名，
   记在 CHANGELOG 里。

其余：`view.h` 在 `API_HEADERS` 里排在 `window.h` 之前；事件类 6 个、枚举 3 个、struct
1 个、类 5 个，`./codegen` 无新增 `skipped`。Flutter 侧 `View`、`TextField`、`EdgeInsets`
与 Flutter 撞名，`nativeapi_flutter` 的导出把它们列入 `hide`，Flutter 用户以
`import 'package:nativeapi/nativeapi.dart' as na;` 使用。

## 9. 现状与未决

已实施：`View` + 四个控件、Absolute / Row / Column、`Window::GetContentView`、五个绑定、
`core/examples/view_example`（登录框）、`tools/gui/core_view_test.py`。

平台验证状态（2026-09-25）：

| 平台 | 状态 |
|---|---|
| macOS | `tools/gui/core_view_test.py` 在本机桌面全过（布局、点击、焦点事件、缩放后重排再点击）；运行它的终端需要辅助功能权限 |
| Windows | MSVC 编译；`tools/gui/core_view_test.ps1` 在 Windows 主机桌面全过，Win32 与 WinUI 3（`NATIVEAPI_ENABLE_WINUI3`）两种构建都是 |
| Linux | Ubuntu 24.04 / GNOME Wayland，应用走 Xwayland（`GDK_BACKEND=x11`）；`tools/gui/core_view_test_linux.py` 全过。GTK 原生 Wayland 后端只能从内部断言，未测 |
| Android / iOS / OHOS | 桩：`IsSupported()` 为 false |

未决：

- **指针事件**（`ViewMousePressedEvent` 等）要不要给 `View`：能做自定义拖拽区和简单画板，
  但和 `WindowDragSession`、`DropTarget` 的坐标与命中语义要对齐。先不做。
- **多行文本高度**：`Label` 的固有高度不随宽度换行而变（单趟布局）。需要时再加两趟。
- **WinUI 3 根视图独占整个客户区**：Island 盖在宿主框架的子窗口之上并接收整块区域的输入，
  所以 Flutter / GPUI 窗口里要用 Native 后端。只盖住子视图所在区域需要 XAML 的命中测试
  配合，先不做。
- **焦点事件的覆盖面**：macOS 只有 `TextField` 发 `ViewFocusedEvent` / `ViewBlurredEvent`
  （成为第一响应者 / 字段编辑器结束时），按钮默认不接受键盘焦点所以不发；Windows / Linux
  按各自控件的焦点通知发，按钮也发。
- **没有视图级的尺寸变化事件**：Linux 上 `WindowResizedEvent` 早于 GTK 给内容分配尺寸，
  在它的监听器里读到的子视图 frame 还是旧的。需要「布局完成」的时机再加
  `ViewResizedEvent`。
- **后续控件**，按需要加、每个一步：`Checkbox`（`SetChecked` / `CheckboxToggledEvent`）、
  `Dropdown`（`SetItems` / `SetSelectedIndex` / `DropdownSelectionChangedEvent`）、
  `Slider`（`SetMinimumValue` / `SetMaximumValue` / `SetValue` / `SliderValueChangedEvent`）、
  `ProgressBar`（`SetValue` / `SetIndeterminate`）、`Separator`。三平台的原生对应都现成
  （`NSButton` checkbox / `NSPopUpButton` / `NSSlider` / `NSProgressIndicator` / `NSBox`；
  `BUTTON` / `COMBOBOX` / `msctls_trackbar32` / `msctls_progress32` / `STATIC`；
  `GtkCheckButton` / `GtkComboBoxText` / `GtkScale` / `GtkProgressBar` / `GtkSeparator`），
  加入时只需在 `view.h` 追加类、追加一个带 `Base = View` 的 tag、在 `view_controls_<os>`
  里加实现。
- **`Switch` / `RadioGroup`**：Windows 经典控件没有原生 switch；radio 需要分组语义。
  等 WinUI3 backend 或有人要。
- **可访问性标签**：`SetAccessibilityLabel` 在三平台都便宜，但 `AccessibilityManager`
  的形态未定（[managers.md](managers.md) §5），先不引入第二处 accessibility 词汇。
- **`Text*` 四属性的重复声明**：`Checkbox` 等带文本的控件加进来时，重新评估抽
  `TextView` 中间层是否值得让句柄表的基类链多走一级（它已支持到 4 层）。

## 10. 检查单（再加控件时用）

- [ ] 派生类只声明自己的方法；共有的东西在 `View` 上，不在派生类上重复。
- [ ] 新控件的 `IdTypeTag` 追加在 24 之后并声明 `using Base = View;`，不改其他号。
- [ ] 父强持子、子弱引用父；`AddSubview` 已有父的 View 先移除。
- [ ] 根 View 析构不销毁原生对象；非根 View 析构销毁。
- [ ] 布局算法只在 `view.cpp`；平台只实现设 frame、读固有尺寸、尺寸变化回调。
- [ ] 六个平台文件都存在；移动端 `IsSupported()` 为 false 且所有方法 no-op。
- [ ] `./codegen` 对 `view.h` 无 `skipped`；C 函数名没有 `_with_`。
- [ ] 五个绑定里 `Button` 都是 `View` 的子类型，能直接传给 `add_subview`。
- [ ] `nativeapi_flutter` 的导出 `hide` 了与 Flutter 撞名的类。
- [ ] 例子 `examples/view_example` 覆盖 §2 的登录框，三平台各跑一次
      （`gui-test` 技能）。
