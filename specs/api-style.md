# API 风格规范：公共接口长什么样

> 状态：已实施（存量缺口在文内逐条标注；错误模型未决，见 §4）
> 适用范围：`core/src/*.h` 与 `core/src/foundation/*.h` 的全部公共声明
> 核实基准：2026-09-17，core `c344e71`，29 个接口层头文件、18 个 `enum class`

本规范回答：**一个新的公共方法 / 类型 / 枚举，该叫什么名字、收什么参数、返回什么、
失败时怎么说、注释怎么写。**

其余几篇管的是结构（放哪一层、谁持有、怎么藏平台代码）；这一篇管的是**表面**——
用户和三个语言绑定直接看到的那一层。规则全部从现有头文件归纳，数字可复核；
有分歧的地方取**多数派且与最近新增代码一致**的一边为规则，另一边列为存量缺口。

## 0. 一条总纲

**公共头里 public 的东西，会原样变成 C 函数、再变成 Dart / Rust / C# 的 API。**
codegen 不做取舍（[c-abi.md](c-abi.md)），所以这里没有「只是 C++ 侧的小细节」：
少一个 `const`，绑定里属性就变成方法；多一个重载，C 函数名就多一截 `_with_xxx`；
用了一个过不了桥的类型，方法会被**静默跳过**（只有一行 warning）。§7 列出硬约束。

## 1. 词汇表：方法怎么命名

### 1.1 属性

| 形态 | 写法 | 例 |
|---|---|---|
| 一般属性 | `void SetX(v)` / `T GetX() const` | `SetOpacity` / `GetOpacity` |
| 布尔属性 | `void SetX(bool)` / `bool IsX() const` | `SetResizable` / `IsResizable` |
| 布尔属性，名词性 | `SetHasX(bool)` / `HasX() const` | `SetHasShadow` / `HasShadow`（全库仅此一对） |
| 只读属性 | 只有 getter | `Display::GetScaleFactor` |

- **setter 在前、getter 紧随其后**，成对声明，中间不插别的方法。
- 布尔属性名是形容词或分词：`Visible`、`Enabled`、`Resizable`、`AlwaysOnTop`、
  `NonActivating`。读出来要是一句话：「is resizable」。`IsIgnoreMouseEvents` 不成话，
  是已知反例，不要照着起名。
- getter 一律 `const`。这不只是洁癖：codegen 只把 **const + 无参 + `Get`/`Is`/`Has`
  前缀**的方法识别为属性（`Method::is_accessor`），绑定里去掉 `Get` 前缀暴露成属性。
  漏了 `const`，它在 Dart / C# 里就成了方法。存量缺口 25 处，集中在 `TrayIcon`（7）、
  `ShortcutManager`（7）、`WindowManager`（4）、`TrayManager`（3）、`DisplayManager`（3）、
  `AccessibilityManager`（1）。

### 1.2 动作

接收者就是宾语时，用**不带宾语的祈使动词**：`Show`、`Hide`、`Focus`、`Blur`、
`Maximize`、`Center`、`Open`、`Close`、`Start`、`Cancel`、`Run`、`Quit`。
不写成 `ShowWindow()`、`OpenDialog()`。

动作成对出现，反向动作用固定的对子，不自造：

| 正向 | 反向 | 状态查询 |
|---|---|---|
| `Show` / `ShowInactive` | `Hide` | `IsVisible` |
| `Focus` | `Blur` | `IsFocused` |
| `Maximize` | `Unmaximize` | `IsMaximized` |
| `Minimize` | `Restore` | `IsMinimized` |
| `Open` | `Close` | `IsOpen` |
| `Start` | `Stop` / `Cancel` | `IsActive` / `IsMonitoring` |
| `Enable` | `Disable` | `IsEnabled` |
| `Register` | `Unregister` | — |

每个有持续状态的动作都配一个 `IsXxx() const` 查询。由用户手势驱动的交互过程用
`StartXxxing`：`StartDragging()`、`StartResizing(ResizeEdge)`。

`Show`/`Hide` 与 `SetVisible(bool)` 两种可见性写法并存（`Window` 用前者，`TrayIcon`、
`Application::SetDockIconVisible` 用后者），取舍未决。在它定下来之前，
**同一个类里只用一种**，新的窗口类对象跟 `Window`。

### 1.3 集合

以 `Menu` 为范本：

```cpp
void AddItem(std::shared_ptr<MenuItem> item);
void InsertItem(size_t index, std::shared_ptr<MenuItem> item);
bool RemoveItem(std::shared_ptr<MenuItem> item);
bool RemoveItemById(MenuItemId item_id);
bool RemoveItemAt(size_t index);
void Clear();
size_t GetItemCount() const;
std::shared_ptr<MenuItem> GetItemAt(size_t index) const;
std::shared_ptr<MenuItem> GetItemById(MenuItemId item_id) const;
std::vector<std::shared_ptr<MenuItem>> GetAllItems() const;
```

- 按不同键查找/删除用**不同的名字**（`ById` / `At`），不用重载。
- 删除返回 `bool`（是否真的删掉了），添加返回 `void`。
- manager 上的同形方法省略名词：`Get(id)`、`GetAll()`、`GetCurrent()`、`GetPrimary()`。

### 1.4 能力探测

```cpp
static bool IsSupported();                          // 整个模块在当前平台是否可用
static bool IsBackendSupported(MenuBackend backend); // 某个子能力
```

`static`、名字固定 `IsSupported` / `IsXxxSupported`。最近新增的 `FileDialog`、
`NotificationManager`、`LaunchAtLogin`、`Menu::IsBackendSupported`、
`MessageDialog::IsExtendedSupported` 都是这个形态。存量缺口：`TrayManager`、
`ShortcutManager`、`UrlOpener` 是实例方法，`SecureStorage::IsAvailable` 异名。

### 1.5 工厂与转换

| 形态 | 写法 | 例 |
|---|---|---|
| 身份对象的工厂 | `static std::shared_ptr<T> FromXxx(...)`，失败返回 `nullptr` | `Image::FromFile` |
| 值对象的工厂 | `static T FromXxx(...)` 或语义名，按值返回 | `Color::FromRGBA`、`PositioningStrategy::Absolute` |
| 转出 | `ToXxx() const` | `ToBase64`、`ToRGBA` |
| 落盘 | `bool SaveToFile(path) const` | `Image::SaveToFile` |

### 1.6 重载：能不用就不用

C 没有重载，codegen 给重载方法加参数后缀：`Run(window)` →
`native_application_run_with_window`，`Get(accelerator)` →
`native_shortcut_manager_get_with_accelerator`。这些名字会一路传到三个绑定。

- 语义不同就起不同的名字（§1.3 的 `ById` / `At`）。`ShortcutManager` 的
  `Get` / `Unregister` / `Register` 三组重载是存量缺口。
- 构造函数的便利重载可以接受（`Preferences()` / `Preferences(scope)`）。
- **替换而不是重载**：旧签名是桩或已被取代时直接改掉。先例：无参 `StartResizing()`
  被 `StartResizing(ResizeEdge)` 替换，没有留两个版本（core `eb57c8e`）。
- 默认实参只给「末位、有显然中性值」的参数：`Quit(int exit_code = 0)`、
  `Open(strategy, placement = Placement::BottomStart)`。C ABI 一侧总是传全参。

### 1.7 名字从哪来

`Window` 的词汇与 Electron `BrowserWindow` / leanflutter `window_manager` 同源
（`Focus`/`Blur`、`SetAlwaysOnTop`、`SetIgnoreMouseEvents`、`SetVisibleOnAllWorkspaces`、
`SetHasShadow`、`SetFullScreenable`）；`Placement` 的 12 个值与 floating-ui 同名。
**新增能力先查这几处有没有既定名字**，有就沿用，让用户的肌肉记忆直接迁移。
平台原生叫法（`NSPanel`、`WS_EX_NOACTIVATE`）只出现在注释的平台说明里，不进方法名。

例外是平台独有的概念本身——`SetDockIconVisible`、`MenuBackend::WinUI3`、
`VisualEffect::Mica`——允许带平台词，但必须按 §5 写清其他平台的行为。

起类型名时顺手查一下与绑定宿主框架的撞名：`Image`、`Brightness` 已经与 Flutter
`dart:ui` 冲突，用户得 `hide` 或加前缀。撞了不是禁止，但要是有同样好的名字就换一个。

## 2. 参数与返回类型

| 类型 | 入参 | 返回 |
|---|---|---|
| `std::string` | `const std::string&` | `std::string` 按值 |
| 几何 / 颜色（`Point` `Size` `Rectangle` `Color`） | 按值 | 按值 |
| 身份对象 | `std::shared_ptr<T>` 按值；`nullptr` = 清除 | `std::shared_ptr<T>`；`nullptr` = 没有 |
| 可清空的字符串属性 | `const std::optional<std::string>&` | `std::optional<std::string>` |
| 枚举 | 按值 | 按值 |
| ID | `XxxId` 别名，不写裸 `int` / `unsigned` | 同左 |
| 字符串列表 | `const std::vector<std::string>&` | `std::vector<std::string>` |
| 对象列表 | — | `std::vector<std::shared_ptr<T>>` |
| 回调 | `std::function<void(...)>` 按值 | 不返回回调 |
| 比例、进度、几何标量 | `double` | `double` |
| 下标、数量 | `size_t` | `size_t` |

细则与存量缺口：

1. **字符串入参** 66 处 `const std::string&`，唯一按值的是 `Window::SetTitle(std::string)`。
2. **几何入参** 按值 14 处、`const&` 7 处（`PositioningStrategy` 4 处、`Window` 的
   `Color` 3 处）。最近新增的 `GetWindowAtPoint`、`WindowDragSession::Start` 都按值。
   两种写法过 C ABI 结果相同，改到时顺手统一，不必专门 sweep。
3. **身份对象绝不以 `const T&` 或 `T*` 进出公共 API**——那绕开了 `shared_ptr` 生命周期
   （[object-model.md](object-model.md) §2）。`PositioningStrategy::Relative(const Window&)`
   及其 `GetRelativeWindow()` 是已知违规，后者已因此被 codegen 跳过。
4. **`std::optional` 只包字符串。** C ABI 用空指针表示缺席，所以只有 C 形态是指针的类型
   能包（`TypeRef::Optional`）；`optional<double>`、`optional<Point>`、`optional<枚举>`
   过不了桥。句柄的「无」用 `nullptr`，不写 `optional<shared_ptr<T>>`。
   可清空属性 get/set 必须对称：`MenuItem::SetAccelerator` 收
   optional 而 `GetAccelerator` 返回裸值是反例。入参形式 `MenuItem` 用 `const&`（3 处）、
   `TrayIcon` 按值（2 处），以前者为准——与字符串规则一致。
5. **getter 不返回引用。** 身份对象属性活读，没有可供引用的稳定存储；事件 getter 也按值，
   `NotificationActivatedEvent::GetArgument()` 返回 `const std::string&` 是唯一例外，别学。
6. **浮点统一 `double`。** `Window::SetOpacity(float)` 是全库唯一的 `float`。
7. **布尔 setter 的参数名** 用 `is_` 前缀，与 getter 对应：`SetResizable(bool is_resizable)`。
   14 处如此；`enabled`（4）、`visible`（2）是存量。`SetHasShadow(bool has_shadow)` 同理。
8. 不出现：裸指针（`void*` 原生对象与 `const char*` 除外）、输出参数、`std::pair` /
   `std::tuple`、模板方法、运算符。多值返回就定义一个值 struct。

## 3. 类型定义

### 3.1 枚举

```cpp
enum class TitleBarStyle {
  /** 每个值都有注释 */
  Normal,
  Hidden
};
```

- `enum class`，类型名与值均 PascalCase，**不加 `k` 前缀**。18 个枚举里
  `DisplayOrientation`、`UrlOpenErrorCode` 两个带 `k`，是存量缺口。
- 值从 0 顺序编号，不赋魔数。`DisplayOrientation` 用角度当值（90/180/270）是反例，
  已原样漏进 C 枚举。
- **第一个值是中性 / 默认值**：`None`、`Normal`、`System`、`Native`、`Unchecked`、
  `Global`。有默认语义的 11 个枚举全部如此，它同时是资源失效时 getter 的返回值。
- 定义在命名空间作用域、放在使用它的类之前。`PositioningStrategy::Type` 是唯一的嵌套枚举。
- 通用词加领域前缀（`MenuItemType`、`DialogModality`、`FileDialogMode`），
  自成概念的不加（`Placement`、`ResizeEdge`、`VisualEffect`）。
- 追加值只能加在末尾——值会固化进 C ABI 和三个绑定。

### 3.2 struct

值对象（[object-model.md](object-model.md) §3）用 `struct`：public 字段 snake_case、
无尾下划线，可带 `static` 工厂和 `const` 方法，不带会改状态的方法——codegen 只导出这两种。

- options：`XxxOptions`，字段带默认成员初始化（`ShortcutOptions`，目前唯一）。
- result：`XxxResult`（`UrlOpenResult`，目前唯一，见 §4）。

### 3.3 类的骨架

```cpp
class Foo : public EventEmitter<FooEvent>, public NativeObjectProvider {
 public:
  static bool IsSupported();          // 1. 静态：GetInstance / IsSupported / 工厂

  Foo();                              // 2. 构造、析构
  explicit Foo(void* native_foo);     //    单参构造一律 explicit
  virtual ~Foo();

  Foo(const Foo&) = delete;           // 3. 四件套，紧跟析构，放 public
  Foo& operator=(const Foo&) = delete;
  Foo(Foo&&) = delete;
  Foo& operator=(Foo&&) = delete;

  FooId GetId() const;                // 4. 身份
                                      // 5. 按功能分组的方法，组内 setter → getter
 protected:
  void StartEventListening() override;
  void* GetNativeObjectInternal() const override;

 private:
  class Impl;
  std::unique_ptr<Impl> pimpl_;       // 私有区只有这两行
};
```

- 四件套的位置存量有三种（析构后 / 方法末尾 / private 区）；最近新增的
  `WindowDragSession`、`FileDialog`、`NotificationManager`、`Display` 都紧跟构造析构，以此为准。
- 单参构造 `explicit`：`Window(void*)`、`TrayIcon(void*)` 缺；
  事件类单参构造 11 个 explicit、9 个没有（`TrayIcon` / `Menu` / `Application` 三组）。
- **public 区不放内部方法。** public 即导出：`ShortcutManager::EmitShortcutActivated`、
  `WindowManager::HandleWillShow` 已经成了 C 函数（[c-abi.md](c-abi.md) §7）。内部入口放
  `private` + `friend`，或者放进 `Impl`。
- **`Impl` 不放 public。** `AppInfo`、`DeviceInfo`、`UrlOpener`、`ShortcutManager` 四个头
  把抽象 `Impl` 开在 public 区，不属于 [platform-seam.md](platform-seam.md) 的任何一种
  接缝形态（该篇 §4.4）。新模块不要复制这个写法，哪怕它是最近的样本。

### 3.4 头文件

- `#pragma once`；标准库包含在前、项目包含在后，项目包含写相对 `src/` 的路径
  （`"foundation/geometry.h"`）。
- 只以 `shared_ptr<T>` 形式出现的类型用前向声明（`class Image;`、`class Window;`），不包含头文件。
- 全部在 `namespace nativeapi` 内，结尾写 `}  // namespace nativeapi`。
- 一个头一个模块，文件名是主类的 snake_case。头内顺序：`XxxId` 别名 → 枚举 →
  类；事件类跟着它所描述的对象走（`WindowEvent` 在 `window.h`，尽管发射者是
  `WindowManager`），同头有发射者时事件写在发射者之前。
- ID 别名当前写作 `typedef IdAllocator::IdType XxxId;`（7 处，其中 `ShortcutId` 在
  `shortcut.h` 与 `shortcut_manager.h` 重复定义，属存量缺口）。

## 4. 失败怎么表达

统一错误模型**未决**。在它落定之前，新代码按现行多数做法：

| 情形 | 表达 |
|---|---|
| 在所有支持的平台上都不会失败，或只是记录一个状态 | `void` |
| 某些平台不支持，或调用可能失败 | `bool`；`@return` 写清 `false` 的含义 |
| 查找、工厂 | `nullptr` |
| 信息类 getter 取不到值 | 空字符串 / 空 vector，注释里写明 |
| 底层资源已消失 | getter 返回类型默认值（[object-model.md](object-model.md) §2 规则 4） |
| 异步才知道的失败 | 失败事件（`ShortcutRegistrationFailedEvent`） |

- **公共 API 不抛异常。** 异常过不了 C ABI。`Color::FromHex` 抛
  `std::invalid_argument` 是目前唯一的违规。平台实现内部用异常
  可以，但必须在到达公共方法返回之前接住。
- 最近新增的可失败调用全部返回 `bool`：`Application::SetProgressBar` / `SetBadgeLabel` /
  `SetBrightness`、`Window::SetTitleBarColors`、`Menu::SetBackend`、
  `WindowDragSession::Start`、`MessageDialog::SetXxx`。`Window` 早期 setter 全是 `void`，
  属于上表第一行，不必回改。
- **不要再发明新的失败通道。** `UrlOpenResult`（结构化结果，1 处）和 `GetLastError()`
  （`FileDialog`、`NotificationManager`，2 处）已经让全库的失败表达达到六种。调用方确实需要
  失败原因时，先把统一模型定下来（C ABI 一侧的候选见 [c-abi.md](c-abi.md) §7），
  而不是在新模块里再造一种。

## 5. 平台差异写在注释里，不写在签名里

每个公共 API 在六个平台上**都存在**。不支持的平台上它是 no-op / 返回 `false` / 返回
默认值——不是 `#ifdef`，不是缺符号（[platform-seam.md](platform-seam.md) §1）。

行为因平台而异的方法，注释里必须带这一块，六行写全：

```cpp
 * @note Platform availability:
 * - macOS: ✅ Fully supported - <实际行为>
 * - Windows: ⚠️ Recorded only - <差异>
 * - Linux: ⚠️ ...
 * - Android: ❌ Not applicable - Always ignored
 * - iOS: ❌ Not applicable - Always ignored
 * - OpenHarmony: ❌ Not applicable - Always ignored
```

三档含义固定：✅ 行为与描述一致；⚠️ 可调用但行为打折（写明怎么打折）；❌ 调用被忽略。
成对的 getter 用 `@see SetXxx() for platform availability.` 指过去，不重复写。
当前 `window.h` 7 块、`application.h` 3 块。

整个模块在某平台不可用 → §1.4 的 `IsSupported()`；模块可用但某个子能力不可用 →
`IsXxxSupported()` + 该方法返回 `false`。

## 6. 注释

- Doxygen 块注释 `/** ... */`，英文。`@brief` 一句话，setter 用 *Sets…*、布尔 getter 用
  *Checks if…*；然后 `@param`、`@return`，再是展开说明，最后 `@note` / `@see`。
- 类注释写三件事：它是什么、数据从哪个平台来源取、一段 `@code` 典型用法（`app_info.h`
  是范本）。
- `@return` 对 `bool` 必须说明 `false` 意味着什么；对 `shared_ptr` 说明何时为 `nullptr`。
- 参数有单位、坐标系、取值范围的都写出来（「relative to its top-left frame corner」
  「in the range 0.0 to 1.0」）。
- **示例只能调用存在的 API。** 存量里有一批示例引用不存在的 API：
  `WindowManager::Create(options)`（`window_manager.h`、`application.h`、
  `positioning_strategy.h`）、`Menu::CreateItem`（`tray_icon.h`）、`Image::FromRawData` /
  `FromSystemIcon` / `IsValid`（`tray_icon.h`、`menu.h`、`image.h`）。改签名时 grep 一遍旧名字。
- `file_dialog.h`、`notification_manager.h` 的单行注释、缺 `@param` / `@return`、缺命名空间
  结尾注释，是存量缺口，不是可选的简写风格。

## 7. codegen 硬约束

写完头文件跑 `./codegen`，**输出里不能有针对新 API 的 `skipped`**。当前基线是 8 条，
都是已知项。

| 约束 | 后果 |
|---|---|
| 签名只用 §2 表内的类型 | 其他类型 → 整个方法被跳过 |
| `std::map` 只支持 `<string, string>` | 同上 |
| `std::vector` 只支持句柄和字符串元素 | 同上 |
| `std::function` 只支持返回 `void` | 同上 |
| 自由函数、运算符不导出 | `RunApp()`、`ModifierKey` 的 `operator\|` 已被跳过 |
| 单例靠方法名 `GetInstance` 识别 | 改名就变成实例类 |
| 事件负载 = 事件类上的 `GetXxx() const` | 名字去掉 `Get` 即 C struct 字段名；类型不支持的字段静默丢失 |
| 抽象基类不导出 | `Dialog` 在 C 侧不存在；要过桥的方法得在派生类上声明 |
| struct 只导出 `static` 与 `const` 方法 | 会改状态的方法被忽略 |

事件 getter 带上领域词：`GetWindowId()`、`GetTrayIconId()`、`GetMenuId()`，而不是
`GetId()`——它会变成 C struct 的字段名，多个领域的事件在绑定里并排出现时要能分辨。
`MenuItemClickedEvent::GetItemId()` 少了前缀，是存量。

## 8. 新能力放哪

1. **对象级的放对象，应用级的放 `Application`，系统枚举放 manager。**
   任务栏进度 / 角标 / 明暗模式最终落在 `Application` 而不是 `Window`（core `f370b36`）。
2. manager 不收纳与自身领域无关的能力（[managers.md](managers.md) §3，
   `DisplayManager::GetCursorPosition` 是反例）。
3. **「在 X 之前拦截」用对象上的可取消事件，不再新增 `SetWillXxxHook`。**
   `WindowManager` 的 will-show / will-hide 钩子正在退役：
   全局钩子只给一个 `WindowId`、同步回调与宿主窗口系统互相打架。替代形态是
   `WindowCloseRequestedEvent` 这类带否决权的事件，落在各平台原生的否决点上。
4. 事件命名：已发生用过去分词（`WindowFocusedEvent`、`MenuOpenedEvent`），可被拒绝的请求
   用 `…RequestedEvent`，即将发生用 `…ingEvent`（`ApplicationExitingEvent`）。
   不用 `Will` / `Did` / `On` 前缀。层级与派发规则见 [event-system.md](event-system.md)。

## 9. 检查单

- [ ] 名字查过 §1.7 的来源；动作有反向对子和 `IsXxx` 查询；没有新增重载。
- [ ] getter 全部 `const`；setter / getter 成对相邻；布尔参数 `is_` 前缀。
- [ ] 参数和返回类型都在 §2 表内；身份对象只以 `shared_ptr` 进出；`optional` 只包字符串且 get/set 对称。
- [ ] 新枚举：PascalCase、无 `k`、从 0 顺序、首值为中性值、每个值有注释。
- [ ] 类骨架按 §3.3：单参构造 `explicit`、四件套紧跟析构、public 区没有内部方法、`Impl` 在 private。
- [ ] 可失败的调用返回 `bool` 并写明 `false` 的含义；没有抛异常；没有新的错误通道。
- [ ] 行为有平台差异的方法带六行 `Platform availability`。
- [ ] 注释里的示例代码能编译。
- [ ] `./codegen` 输出没有新的 `skipped`；生成的 C 函数名读得通（没有意外的 `_with_`）。
