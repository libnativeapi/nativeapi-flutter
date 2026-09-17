# 单例与注册表规范

> 状态：已实施（单例写法已统一为 Meyer's；能力型 API 形态与注册语义未决，见 §5）
> 适用范围：`core/src/` 全部 `GetInstance()` 类型
> 核实基准：2026-08-25，11 个单例全部为 Meyer's

本规范回答：**系统级资源由谁持有、怎么访问、跟 ID 查找表和句柄表是什么关系。**
对象本身的语义见 [object-model.md](object-model.md)。

## 1. 单例清单

| 单例 | 角色 |
|---|---|
| `WindowManager` | 窗口的创建、枚举、平台事件转发 |
| `DisplayManager` | 显示器枚举、实例缓存与 diff |
| `TrayManager` | 托盘图标集合 |
| `ShortcutManager` | 全局快捷键注册 |
| `Application` | 应用级生命周期与事件 |
| `AccessibilityManager` | 辅助功能权限 |
| `UrlOpener` | 打开外部 URL |
| `AppInfo` / `DeviceInfo` | 只读的应用 / 设备信息 |
| `WindowRegistry` | `WindowId → shared_ptr<Window>` 查找 |
| `HandleTable`（foundation） | C ABI 句柄表，见 [handle-ownership.md](handle-ownership.md) |

`KeyboardMonitor` **不是**单例——它是可多实例的 `EventEmitter`。旧文档把它列进 manager
清单是错的。

## 2. 唯一合法写法：Meyer's

```cpp
// 头文件
class WindowManager : public EventEmitter<WindowEvent> {
 public:
  static WindowManager& GetInstance();
  virtual ~WindowManager();

  WindowManager(const WindowManager&) = delete;
  WindowManager& operator=(const WindowManager&) = delete;
  WindowManager(WindowManager&&) = delete;
  WindowManager& operator=(WindowManager&&) = delete;

 private:
  WindowManager();                       // 私有构造
  class Impl;
  std::unique_ptr<Impl> pimpl_;
};

// 实现
WindowManager& WindowManager::GetInstance() {
  static WindowManager instance;         // C++11 起，初始化是线程安全的
  return instance;
}
```

规则：

1. **函数内 `static` 局部变量**，不用裸静态指针，不用 `std::once_flag`，不用堆分配。
   `DisplayManager` 曾用手写 `static DisplayManager* instance_`，已收敛。
2. 构造函数私有；拷贝/移动四件套全部 `delete`。当前只有
   `accessibility_manager.h` 少了移动两件（仅写了拷贝两件），属于待补齐的不一致。
3. `GetInstance()` 返回**引用**。调用方不得取地址存进 `shared_ptr`/`unique_ptr`，
   不得 `delete`。
4. 单例自身通常也用 PIMPL 或窄接缝（[platform-seam.md](platform-seam.md)）。

### 2.1 静态析构顺序

Meyer's 单例在首次调用时构造、在静态析构阶段销毁，**销毁顺序不确定**。因此：

- 一个单例的析构函数里不要调用另一个单例的 `GetInstance()`——对方可能已经没了。
- 全局对象/静态变量的析构函数里不要碰单例，同理。
- 需要确定性的关停顺序，就提供显式的 `Shutdown()` 由应用在退出前调用，
  不要依赖析构顺序。

## 3. Manager 的职责

Manager 该做的：

1. **实例去重**：同一底层资源的重复查询返回同一个 `shared_ptr`
   （[object-model.md](object-model.md) §2 规则 3）。`DisplayManager` 按平台身份 key
   缓存即此。
2. **发领域事件**：manager 是 `EventEmitter`，平台回调转成库事件由它发射。
3. **管平台监控的启停**：通过 `Start`/`StopEventListening`
   （[event-system.md](event-system.md) §4），不在构造函数里无条件开启。

Manager 不该做的：

- 不承载与自身领域无关的能力（`DisplayManager::GetCursorPosition()` 属于越界——
  它该属于未来的 Cursor / Mouse API）。
- 不把平台内部机制开成公共方法（`WindowManager` 的 swizzle 钩子已被 codegen 原样
  导出成 8 个 C 函数；这组钩子正在退役，见 [api-style.md](api-style.md) §8）。

## 4. 三张表的分工

三者都是「按某个键找到对象」，但服务的对象不同，**不可互相替代**：

| | 键 | 值 | 服务谁 | 管什么 |
|---|---|---|---|---|
| Manager 缓存 | 平台身份（私有） | `shared_ptr<T>` | C++ 侧 | 实例去重 |
| `WindowRegistry` | `WindowId` | `shared_ptr<Window>` | C++ 侧 | 按 ID 查找 |
| `HandleTable` | `native_*_t`（uint64） | `shared_ptr<void>` + 类型 tag | C ABI | 跨语言引用生命周期 |

事件负载里带的是 `WindowId`，`WindowManager::Get(id)` 依赖 `WindowRegistry`，
这条查找路径句柄表替代不了。反过来，句柄的世代校验和类型校验也不是注册表的职责。
详见 [handle-ownership.md](handle-ownership.md) §2.3。

`WindowRegistry` 内部是 `ObjectRegistry<Window, WindowId>`
（`foundation/object_registry.h`）——一个加锁的 `unordered_map` 模板，当前只有这一个
使用者。需要第二张同形状的表时复用它，不要另写。

### 4.1 注册表条目的移除时机

`WindowRegistry` 是**以 WindowId 为键的包装对象缓存，不是所有权登记表**。同一个原生
窗口可以有多个 `Window` 包装对象共享一个 WindowId，因此**不能**在 `~Window()` 里注销
——任一临时包装对象析构都会把条目删掉，而原生窗口还活着。

正确的时机是原生窗口关闭（macOS `NSWindowWillCloseNotification`、Windows
`WM_NCDESTROY`、GTK `destroy`）。这项尚未在各平台接齐，进度见
[handle-ownership.md](handle-ownership.md) §2.4。

## 5. 未决

- **能力型 API 形态分裂**：`UrlOpener` 是单例，`LaunchAtLogin` 是多实例，
  `AccessibilityManager` 是单例但只有两个方法（有 `Enable()` 无 `Disable()`，
  `IsEnabled()` 只读本地 flag 而不查系统授权状态）。无状态能力型 API 该统一成 static
  函数集还是保留单例，尚未选定；新模块先跟最近的 `AppInfo` / `DeviceInfo`（单例）。
- **对象创建 / 注册模式不统一**：`Window()` 构造即隐式注册进 `WindowRegistry`；
  `TrayIcon` 文档要求直接 `make_shared`，`TrayManager` 却又维护 `trays_` 映射，注册路径
  不明；`Shortcut` 必须走 `ShortcutManager::Register`；`Image` 只能走静态工厂。
  `WindowManager::Create(options)` 在多处文档示例里出现但**并不存在**——补上它还是清掉
  示例，二选一。
- **ID 计数器双轨**：`TrayManager::next_tray_id_`、`ShortcutManager::next_shortcut_id_`
  与 `IdAllocator` 并存，应统一走后者；`ShortcutId` 在 `shortcut.h` 与
  `shortcut_manager.h` 重复定义。
- 能力探测的命名与形态见 [api-style.md](api-style.md) §1.4。

## 6. 检查单

- [ ] 新单例用 Meyer's：函数内 `static`、私有构造、四件套 `delete`、返回引用。
- [ ] 析构函数不触碰其他单例。
- [ ] 平台监控走 `Start`/`StopEventListening`，不在构造函数里开。
- [ ] 需要按 ID 查找：先看能否复用 `ObjectRegistry`。
- [ ] 想加公共方法前，先确认它属于这个 manager 的领域（§3）。
- [ ] 真的需要单例吗——多实例类型（如 `KeyboardMonitor`）不要塞进这套模式。
