# C ABI 句柄所有权规则

状态：**已决策，实施中**
核实基准：2026-08-31 —— `g_windows` 已确认消灭；`window_windows.cpp:200`、
`window_manager_macos.mm:169` 两处行号引用仍准确

本文是 C ABI 句柄语义的唯一权威说明。绑定作者和纯 C 调用方都以此为准。

---

## 一、要解决的问题

改造前，同为 `void*` 的句柄在库里有两套**语义相反**的含义，而且分裂正好沿着「生成的 / 手写的」边界展开：

| | 生成的模块（display / preferences / …） | 手写的模块（window / menu / tray_icon / …） |
|---|---|---|
| 句柄含义 | 堆上的**独立拷贝**（`new Display(items[i])`） | 指向库内 `shared_ptr` 所持对象的**活引用** |
| 所有权 | 调用方独占，必须 `native_display_free` | 库持有，`destroy` 只是从 side map 里 erase |
| 数据新鲜度 | 快照，之后不反映底层变化 | 实时 |
| 传错的后果 | 对活引用调 `_free` → **直接 delete 掉库内对象** | 对拷贝调 `destroy` → 静默 no-op 后泄漏 |

两者在 C 头文件里都是 `typedef void* native_xxx_t`——**调用方无法区分，编译器也无法区分**。

同时句柄是裸指针：`native_window_destroy` 先解引用取 ID 再 erase，句柄失效后调用方手里的 `void*` 变成悬垂指针，而 70+ 个 `native_window_*` 函数没有一处做有效性校验。对要喂给 Dart / Swift 这类 GC 语言的 FFI 层，finalizer 执行时机不确定，**double-free 和 UAF 是必然而非偶然**。

---

## 二、决策

### 2.1 句柄一律是「活引用」

句柄表持有 `shared_ptr`，解析时返回副本。调用期间对象保证存活。

**值快照语义只保留给纯数据类型**——`Point` / `Size` / `Rectangle` / `Color` 这类已经按 struct 传值的东西。它们本来就不是句柄。

被否决的方案：让句柄一律是值拷贝。理由是 `Window` / `Menu` / `TrayIcon` 本质是对**平台原生对象的引用**，拷贝它们没有意义——两个 `Window` 拷贝指向同一个 `NSWindow`，「独立拷贝」是幻觉。而 `Display` 之所以能拷贝，只是因为它恰好是一份只读快照数据。为了少数只读类型牺牲整体一致性不划算。

### 2.2 句柄是不透明整数，不是指针

```c
typedef uint64_t native_handle_t;
#define NATIVE_INVALID_HANDLE ((native_handle_t)0)
```

编码：`[ 世代 32 位 | 槽位索引 32 位 ]`

解析时三重校验：

1. 槽位存在
2. `slot.generation == handle.generation` —— 否则句柄已失效
3. `slot.type_tag == IdTypeTag<T>::value` —— 否则类型不匹配

释放时清空槽位内容并 `++generation`，**所有指向该槽位的旧句柄自动失效**。

收益：

- 失效句柄的任何操作都**安全失败**，不解引用悬垂内存。GC 语言 finalizer 场景的刚需。
- 类型混淆被挡住：把 `native_menu_t` 传给 `native_window_show` 会被 type_tag 拦截。
- `shared_ptr` 跨 ABI 的问题自然消解——这正是 codegen README 里标记为「全仓库最大单点阻塞」的那 27 处签名的通解。
- `g_windows` 这本私账被句柄表取代。

### 2.3 澄清：句柄表不取代 `WindowRegistry`

早期审查稿说「三套账本合并为句柄表这一个真相来源」。实际读代码后这是不准确的，记录在此以免后续照做：

- **句柄表**：`handle → shared_ptr<T>`，服务 C ABI，管的是**跨语言引用的生命周期**。
- **`WindowRegistry`**：`WindowId → shared_ptr<Window>`，服务 C++ 侧，管的是**按 ID 查找窗口**。事件负载里带的是 `WindowId`，`WindowManager::Get(id)` 也依赖它。这个查找无法由句柄表替代。

真正要消灭的只有 `g_windows`——它是 `WindowRegistry` 的纯粹重复，存在的唯一理由是给 C 侧续命。这一条已完成。

### 2.4 窗口注册表的移除时机

**`WindowRegistry` 是以 WindowId 为键的包装对象缓存，不是所有权登记表。** 窗口的真实身份存在原生对象上（macOS 的 `kWindowIdKey` associated object、Windows 的 `kWindowIdProperty`）。同一个 `NSWindow` 可以有多个 `Window` C++ 包装对象，它们共享同一个 WindowId。

因此**不能**把注销放进 `Window::~Window()`：任何一个临时包装对象析构，都会把注册表条目删掉，而原生窗口还活着。`window_windows.cpp:200` 目前正是这么做的，只是常见路径下碰巧不出问题。`window.h` 构造函数文档声称「自动注册到 WindowRegistry」——那个设计本身是错的，文档要改，不是让实现去对齐它。

正确的移除时机是**原生窗口关闭**：

| 平台 | 钩子 | 现状 |
|---|---|---|
| macOS | `NSWindowWillCloseNotification` | 已监听，但 `windowWillClose:` 处理函数**整个是注释掉的空壳**（`window_manager_macos.mm:169`）——这就是 macOS 窗口泄漏的直接原因 |
| Windows | `WM_NCDESTROY` | 未接；现用包装对象析构代替 |
| Linux | GTK `destroy` 信号 | 未接 |
| iOS / Android / OHOS | — | 未接 |

这项尚未实施，是 T4.4 的剩余部分。

### 2.5 释放函数命名（已被 c-abi.md 取代）

> **本节记录的是当时的决策，实施结果不同。以 [c-abi.md](c-abi.md) §3.1 为准。**

当时的方案是把 `native_display_free` / `native_window_destroy` 统一改名为
`native_<type>_release`，理由是调用方释放的是自己那份引用而非对象本身。

实际落地时发现这个方案没有区分**数组**与**数组元素**两级所有权，最终改为三函数
形态：`_free`（释放一份引用）、`_list_free`（连数组带元素一起释放）、
`_list_release`（只释放数组，元素交给调用方）。`destroy` 已从 ABI 中消失。

### 2.6 谁负责释放

| 来源 | 调用方是否要 release |
|---|---|
| `native_x_create*()` | **是** |
| 返回句柄的 getter（如 `native_window_manager_get_current()`） | **是** —— 每次返回都是一份新引用 |
| 列表里的每个句柄（`native_x_list_t`） | 取决于用 `_list_free` 还是 `_list_release`，见 [c-abi.md](c-abi.md) §3.1 |
| 回调参数里的句柄 | **否** —— 仅在回调期间有效，需要留存请自行 retain |

规则简化为一句：**凡是返回 `native_*_t` 的函数，调用方都拥有那份引用并负责 release。** 回调参数是唯一例外。

---

## 三、对现有代码的影响

- 已生成的 16 个 capi 文件要从值拷贝改为活引用；`DisplayManager` 内部需持有 `shared_ptr<Display>`，生成器同步修改。
- 手写模块迁移到句柄表，但**只做机械的句柄封装替换**——签名改造（错误码化）通过 codegen 重新生成落地，不手工编辑即将被删除的文件。
- ~~`native_*_id_t` 目前是 `long`~~ —— 已收敛为 `unsigned int`（与 `IdAllocator::IdType` 同宽）。列表结构体里的 `count` 仍是 `long`，宽度不可移植的问题未清完，见 [c-abi.md](c-abi.md) §7。

**执行顺序上的硬约束**：本文的 2.1 必须在扩大 codegen 覆盖率之前落地。否则每迁移一个模块，就是把「值拷贝 vs 活引用」的分裂复制到下游一次。
