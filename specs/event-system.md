# 事件系统规范

> 状态：已实施（事件归属模型尚未统一，见 §6）
> 适用范围：`core/src/foundation/event.h`、`event_emitter.h`、`dispatcher.h`
>   及 9 个 `EventEmitter` 派生类
> 核实基准：2026-08-25

本规范回答：**事件类怎么定义、怎么发、怎么收、什么时候在哪个线程跑。**
事件里怎么引用对象见 [object-model.md](object-model.md) §5。

## 1. 事件类

全部继承 `Event`（`foundation/event.h`）。基类只给两样东西：构造时记录的
`steady_clock` 时间戳，和**纯虚**的 `GetTypeName()`。

```cpp
class MyEvent : public Event {
 public:
  explicit MyEvent(std::string data) : data_(std::move(data)) {}
  const std::string& GetData() const { return data_; }
  std::string GetTypeName() const override { return "MyEvent"; }   // 纯虚，必须实现
 private:
  std::string data_;
};
```

规则：

1. `GetTypeName()` 是 `= 0`，漏写是编译错误而非运行期缺陷，不必额外检查。
2. **按领域建层级，不要直接继承 `Event`。** 每个领域先有一个基类
   （`WindowEvent`、`WindowDragEvent`、`DisplayEvent`、`TrayIconEvent`、`MenuEvent`、`ShortcutEvent`、
   `KeyboardEvent`、`ApplicationEvent`），具体事件再继承它。八个基类里七个定义在
   `src/<模块>.h`，只有 `KeyboardEvent` 在 `foundation/keyboard.h`——foundation 层
   本不该有领域事件，找不到时按这里查。派发靠
   `dynamic_cast` 匹配，层级就是「监听基类可收到全部子类事件」这一能力的来源。
3. 事件本身是**值对象**：可拷贝、可跨线程传递。不得按值内嵌身份对象
   （[object-model.md](object-model.md) §5）。

## 2. `EventEmitter<Base>`

发事件的类继承 `EventEmitter<领域基类>`。当前 9 个：`WindowManager`、`WindowDragSession`、
`DisplayManager`、`ShortcutManager`、`KeyboardMonitor`、`Application`、
`TrayIcon`、`Menu`、`MenuItem`。

模板内有 `static_assert` 保证 `Base` 派生自 `Event`；`AddListener<T>` 另有
`static_assert` 保证 `T` 派生自 `Base`。

### 2.1 公开面 vs 受保护面

这条边界是设计意图，不是偶然：

| 可见性 | 成员 | 含义 |
|---|---|---|
| public | `AddListener<T>(回调 或 EventListener<T>*)` → `size_t` | 任何人可订阅 |
| public | `RemoveListener(id)`、`RemoveAllListeners<T>()`、`RemoveAllListeners()` | 任何人可退订 |
| public | `GetListenerCount<T>()`、`GetTotalListenerCount()`、`HasListeners<T>()` | 只读 |
| **protected** | `Emit(...)` / `EmitAsync(...)` | **只有类自己能发自己的事件** |
| **protected** | `StartEventListening()` / `StopEventListening()` | 惰性监听钩子 |
| **protected** | `ShutdownEmitter()` | 析构协议 |

外部代码无法伪造某个对象的事件——这是 `Emit` 受保护带来的性质，改动可见性前先想清楚。

### 2.2 派发语义

- `Emit` 在**锁外**回调：先在锁内取监听器快照，再逐个 `Invoke`。因此回调里可以安全
  地重入 emitter（增删监听器）。
- 快照期间被移除的监听器带 `removed` 标记，`Invoke` 前跳过——回调 A 里
  `RemoveListener(B)` 之后，B 不会再被调到。
- 匹配用 `dynamic_cast<const T*>`：注册 `AddListener<WindowEvent>` 会收到全部
  `WindowXxxEvent`；注册 `AddListener<WindowMovedEvent>` 只收该一种。

## 3. 线程模型

**这是最容易记错的一条：`EmitAsync` 投递到平台主线程 / UI 线程，不是后台线程。**

| | `Emit` | `EmitAsync` |
|---|---|---|
| 回调线程 | 调用 `Emit` 的那个线程 | 平台主线程 |
| 时机 | 同步，函数返回前跑完 | 永远延后，即使已在主线程 |
| 底层 | 直接调用 | `RunOnMainThread()`（`foundation/dispatcher.h`） |

选择依据：

- 事件产生自后台线程 → `EmitAsync`。用户回调多半要碰 UI。
- **持锁时发事件 → `EmitAsync`。** `ShortcutManager` 就是这个场景：它在自己的互斥
  量内发射，延后投递才不会让用户回调跑在一把它并不知情的锁下面。
- 其余情况 → `Emit`。

`EmitAsync` 「即使已在主线程也延后」是刻意的：调用点的同步/异步语义不随线程变化，
避免出现「只在某些线程上才重入」的时序 bug。

**Android / OHOS 例外**：这两个平台尚无主线程投递机制，`EmitAsync` 会退化为
**在调用线程上同步投递**——静默丢事件比线程错更糟。跨平台代码不得假设
`EmitAsync` 的回调一定落在主线程。

当前只有 `ShortcutManager` 使用 `EmitAsync`。

### 3.1 用了 `EmitAsync` 就必须处理析构竞态

已投递但未执行的 `EmitAsync` 会落在一个正在析构的对象上。`~EventEmitter()` 里调
`ShutdownEmitter()` 太晚了——那时派生类部分已经析构完。

**规则：任何调用 `EmitAsync` 的派生类，必须在自己析构函数的第一行调
`ShutdownEmitter()`。** 它会阻塞到进行中的派发结束，把 emitter 标记为死亡，之后到达
的投递变成 no-op；幂等，多调无害。

### 3.2 dispatcher 契约（`foundation/dispatcher.h`）

`EmitAsync` 底下是一层可插拔的主线程投递机制，绑定作者与嵌入方需要知道四件事：

- **主线程的认定**：Apple 平台由 OS 判定；其余平台默认认定「加载本库的线程」为
  主线程。假设不成立时（比如从工作线程加载的插件），在使用任何 dispatcher 功能
  之前调 `SetMainThread()`。Windows 上启动时调一次还会顺带初始化派发用的
  message-only 窗口。
- **能力探测**：`IsMainThreadDispatchSupported()` 在 Android / OHOS 返回 false；
  `RunOnMainThread()` 排不进队列时返回 false 且**不执行**传入的函数（本节开头
  `EmitAsync` 的退化行为即源于此）。
- **自带主循环的宿主**：Qt、游戏引擎等用 `SetMainThreadDispatcher()` 把投递接进
  自己的调度器；测试也用它确定性地排空队列。必须在其他线程开始使用 dispatcher
  之前设置——覆盖不做并发同步。
- **没有 UI 循环的消费者**：控制台工具、纯 C 调用方必须周期性调
  `RunMainThreadLoopFor(timeout_ms)`，否则排队的工作永远不会执行。已经在跑
  Cocoa / Win32 / GTK / Flutter 循环的应用**不得**调它——嵌套第二个循环会引入
  重入 bug。

## 4. 惰性监听：`Start` / `StopEventListening`

平台事件监控（全局快捷键钩子、`NSNotification` 观察者、GTK 信号）应该按需开关，
不在构造函数里无条件启动。

`EventEmitter` 在**第一个监听器加入**时调 `StartEventListening()`，在**最后一个移除**
时调 `StopEventListening()`。两者都在锁外调用，实现里可以安全回调 emitter。

```cpp
// tray_icon.h
class TrayIcon : public EventEmitter<TrayIconEvent>, public NativeObjectProvider {
 protected:
  void StartEventListening() override;   // pimpl_->SetupEventMonitoring()
  void StopEventListening() override;    // pimpl_->CleanupEventMonitoring()
};
```

**构造函数里不要再调 `SetupEventMonitoring()`。** 当前重写了这对钩子的有
`WindowManager`、`ShortcutManager`、`TrayIcon`。

平台层的启停实现同样要幂等——`RemoveAllListeners()` 之后再 `AddListener` 会走第二轮
启动。


## 5. 监听器生命周期

- `AddListener` 返回 `size_t` id，退订只认 id。
- 传 `EventListener<T>*` 裸指针的重载**不接管所有权**：监听器对象必须活到退订之后。
  能用 lambda 就用 lambda 重载。
- 在持有 id 的对象析构时退订（RAII）。

## 6. 未决：事件归属模型

同一库里并存四种事件 / 回调模型，新代码按「目标」一列做，存量不要照抄：

| 类 | 现状 | 目标 |
|---|---|---|
| `Window` | 不是 `EventEmitter`，`WindowEvent` 由 `WindowManager` 集中发 | 对象级事件挂对象：`Window` 自己可 `AddListener` |
| `TrayIcon` / `Menu` / `MenuItem` | 各自继承 `EventEmitter`，对象自己发 | 已符合 |
| `Shortcut` | 双轨：`ShortcutOptions::callback` 的 `std::function` + `ShortcutManager` 的 `ShortcutActivatedEvent` | 收敛为事件模型 |
| `KeyboardMonitor` | 手动 `Start()` / `Stop()`，不走惰性监听；公开了 `GetInternalEventEmitter()` | 改用 `Start`/`StopEventListening`，移除该公开方法 |

规则：**对象级事件挂对象，系统级事件（增删、全局监控）挂 manager。** 它会传导到
C ABI——`native_tray_icon_add_listener` 挂在对象上，window 事件却只有
`native_window_manager_add_listener`。

事件类结构上的存量缺口：`WindowEvent` 基类存 id，而 `TrayIconEvent` / `MenuEvent` 基类
为空、各子类重复一份 id 字段（C 侧后果是 id 在每个 union 分支里重复）；Menu 缺
`MenuItemEvent` 中间基类，`MenuId` 与 `MenuItemId` 事件混在同层。新领域一律「基类存 id」。

## 7. 检查单

- [ ] 新事件继承的是**领域基类**，不是 `Event`。
- [ ] `GetTypeName()` 已实现。
- [ ] 事件不按值内嵌身份对象，改带 `shared_ptr` 或整数 ID。
- [ ] 发射者继承 `EventEmitter<领域基类>`；`Emit` 保持受保护。
- [ ] 后台线程或持锁场景用 `EmitAsync`。
- [ ] 用了 `EmitAsync`：析构函数第一行是 `ShutdownEmitter()`。
- [ ] 平台监控放进 `Start`/`StopEventListening`，不放构造函数，且启停幂等。
