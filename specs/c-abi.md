# C ABI 规范：生成管线与类型映射

> 状态：生成管线已实施；错误模型与整数宽度未决（见 §7）
> 适用范围：`core/src/capi/`、`tools/codegen/`
> 核实基准：2026-08-25，28 个 capi 头中 27 个、27 个实现中 26 个为生成产物

本规范回答：**C ABI 长什么样、由谁产出、C++ 类型怎么过桥。**
句柄的所有权与失效语义是独立一篇：[handle-ownership.md](handle-ownership.md)。

## 1. 第一条：不要手写 `capi/`

`src/capi/` 里**唯一**手写的是 `string_utils_c.h` / `string_utils_c.cpp`。其余全部
带横幅：

```
// AUTO-GENERATED. DO NOT EDIT.
// Any manual changes WILL BE LOST when this file is regenerated.
```

改 C ABI 的正确路径永远是：

```bash
# 1. 改 core/src/ 下的 C++ 头
# 2. 需要新增模块时，把头文件加进 tools/codegen/shared/src/lib.rs 的 API_HEADERS
# 3. 在 workspace 根目录
./codegen
```

想让 C ABI 长成某个样子，就去改 C++ 头或改生成器，**不要改产物**。
`./codegen check` 是只读校验，产物过期时非零退出（CI 用）。

一个模块要进 C ABI，必须显式加进 `API_HEADERS`（当前 34 条）。这是刻意的：绑定仓库
里生成文件与手写文件同目录，隐式纳入会静默覆盖别人手写的封装。

## 2. 类型映射

| C++ | C | 形态 |
|---|---|---|
| 身份对象（`shared_ptr<Window>` 等） | `native_window_t` = `uint64_t` | 句柄，见 §3 |
| 值对象（`Point`/`Size`/`Rectangle`/`Color`） | 同名 `native_*_t` struct | 按值 |
| `XxxId`（`IdAllocator::IdType`） | `native_xxx_id_t` = `unsigned int` | 按值 |
| `std::string` | `char*` | 调用方所有，见 §4 |
| `std::vector<shared_ptr<T>>` | `native_x_list_t` | 见 §5 |
| `bool` / 整数 / 浮点 | `stdbool.h` / `stdint.h` 对应类型 | 按值 |
| 监听器 id | `native_listener_id_t` = `uint64_t` | `common_c.h` |

分界线就是 [object-model.md](object-model.md) 的那条：**身份对象走句柄，值对象走
struct。** 新类型过不了桥，先回去确认它的归属，而不是在生成器里开特例。

`common_c.h` 承载跨模块共享的定义（`FFI_PLUGIN_EXPORT` 导出宏、
`native_listener_id_t`、`NATIVE_INVALID_LISTENER_ID`），它本身也是生成的。

## 3. 句柄

`typedef uint64_t native_<类型>_t;`——不透明整数，不是指针。编码为
`[世代 32 位 | 槽位 32 位]`，解析时校验槽位存在、世代匹配、类型 tag 匹配。
失效句柄上的任何操作安全失败，不解引用悬垂内存。

完整规则（谁负责释放、回调参数的例外、世代失效语义）见
[handle-ownership.md](handle-ownership.md)。

### 3.1 释放函数的三种形态

实际落地的不是「统一改名 `_release`」，而是按语义分成三个函数：

| 函数 | 语义 |
|---|---|
| `native_<x>_free(handle)` | 释放调用方持有的**那一份引用**。对无效或已释放的句柄调用是安全的。 |
| `native_<x>_list_free(list*)` | 释放数组，**并**释放其中每一个句柄。 |
| `native_<x>_list_release(list*)` | **只**释放数组；其中的句柄交给调用方接管。 |

`_free` 与 `_list_release` 的区别不是历史包袱，是「要不要连带释放元素」的真实分叉。
绑定层从列表里取走句柄自行管理时用 `_list_release`，一次性用完时用 `_list_free`。

> 这一条取代 [handle-ownership.md](handle-ownership.md) §2.5 提出的「全部改名
> `_release`」——那个方案没有区分数组与元素两级所有权，实施时被上表替换。

## 4. 字符串

返回 `char*` 的 getter，**所有权归调用方**，用 `free_c_str()` 释放
（`string_utils_c.h`，仓库里唯一手写的 capi 模块）。

传入方向用 `const char*`，库内立即拷贝，不留引用。

回调参数里的字符串**只在回调期间有效**，回调返回即失效——需要留存就自行拷贝。

## 5. 列表

```c
typedef struct {
  native_display_t* displays;
  long count;
} native_display_list_t;
```

> `count` 目前是 `long`——Windows 上 32 位、其余平台 64 位，同一个 ABI 宽度不一致。
> 待收敛为固定宽度整数（§7）。新写生成器代码时不要沿用 `long`。

## 6. 事件与回调

事件通过 `add_listener` / `remove_listener` 函数对暴露，注册返回
`native_listener_id_t`，失败返回 `NATIVE_INVALID_LISTENER_ID`（即 0）。

每个领域生成一个事件类型枚举（`NATIVE_DISPLAY_EVENT_TYPE_ADDED` 等）加一个事件
struct，C++ 侧的 `dynamic_cast` 层级在 C 侧摊平成 tag + 联合字段。

回调签名统一带 `void* user_data` 尾参。回调里拿到的句柄和字符串**都不需要也不应该
释放**（[handle-ownership.md](handle-ownership.md) §2.6 的例外条）。

### 6.1 `user_data` 的释放

凡是接收回调的地方——函数参数、`add_listener`、struct 的回调字段——都在
`user_data` 之后再带一个 `native_release_user_data_t`（`common_c.h`，可为
`NULL`）。**什么时候释放由 core 决定，绑定不推测**：

- **恰好一次。** 每次调用都会释放它收到的 `user_data`，包括调用失败、句柄无效、
  回调为 `NULL` 的情况。注册失败时绑定不需要自己清理。
- **在 core 最后一次可能调用该回调之后。** 监听器被移除、回调被替换或清空、注册
  结束、持有者被销毁时，core 都会释放。实现方式是生成的胶水代码在函数开头创建
  `nativeapi::capi::UserData`（`core/src/capi/user_data.h`），并让它随
  `std::function` 被捕获；最后一份拷贝析构时释放。所以 C++ 侧持有回调时必须保证
  调用期间回调不会析构（参见 `Shortcut::Invoke` 的做法）。
- **在主线程上，异步执行。** 释放永远投递到主线程（`RunOnMainThread`），不会在让回调
  离开的那次调用内部执行：绑定的释放函数可能运行任意代码（比如 Rust 闭包的析构），
  不能在 core 某个对象的锁里跑。没有主线程派发机制的平台（Android / OHOS）改为就地
  执行。进程退出、投递失败时直接放弃释放，因为绑定的运行时可能已经不在了。
- 主线程不一定是绑定自己的线程（Dart 的 isolate、`deno desktop` 下的 JS 线程），
  需要切换线程的绑定在自己的释放函数里切换。

struct 里的回调字段在 core 读取这个 struct 时接管（生成的 `to_cpp_*` 转换）。一个
从未传给 core 的 struct，它的 `user_data` 由调用方自己负责。

## 7. 已知未决

写生成器或改 ABI 前先看这几条，避免把问题复制到下游：

| 问题 | 说明 | 方向 |
|---|---|---|
| 没有统一错误模型 | 无 `native_get_last_error` 之类的通道；无效句柄静默返回默认值，调用方分不清「成功返回默认值」与「句柄已失效」。C++ 一侧的现行做法见 [api-style.md](api-style.md) §4 | 在 IR 层统一：状态码 + out 参数，或 thread-local last error |
| 整数宽度不可移植 | `native_*_id_t` 是 `unsigned int` 而非 `uint32_t`；list 的 `count` 是 `long`、`get_size` 返回 `unsigned long`——Windows LLP64 下 32 位、其余平台 64 位，而 Dart / C# / Rust 的 FFI 各自硬编码宽度 | 统一映射为 `<stdint.h>` 定宽类型 |
| 空串与缺失折叠 | `to_c_str` 对空字符串返回 `nullptr`，`optional<string>` 的「未设置」与 `""` 在 ABI 上不可区分，`get_title` 无法往返 | 空串返回合法的 `""` 分配，`nullptr` 只表示无值 |
| 回调 typedef 生成质量 | 同一个 `std::function<void()>` 生成三个名字；`set_will_show_hook` 的回调参数名漏成 `arg0`、类型退化为 `unsigned int` | 相同签名共享 typedef；IR 保留参数名与语义类型 |
| 内部 API 泄漏进 ABI | `native_shortcut_create_with_id_*`、`native_shortcut_manager_emit_shortcut_activated`、`native_window_manager_handle_will_show/hide` 与 `call_original_*`、`native_display_create()` | 给 IR 加 internal / exclude 标注；C++ 一侧的预防见 [api-style.md](api-style.md) §3.3 |
| 重载的 C 命名 | `register_with_accelerator_and_callback`、`get_with_accelerator` 这类机械后缀可读性差 | 在 C++ 层拆名（[api-style.md](api-style.md) §1.6），生成名自然变好 |
| `void*` 包装构造被导出 | `native_window_create_with_native_window` 等接管原生对象，所有权语义在 C 文档里缺失 | 补所有权说明，或随 internal 标注摘除 |
| 导出宏 | `FFI_PLUGIN_EXPORT` 在每个头重复定义；`#if _WIN32` 应为 `#ifdef`；没有 dllimport 分支 | 收敛到统一 export 头 |
| 生成的文档模板 | 所有 `get_native_object` 的注释都是 display 的（「NSScreen*, HMONITOR…」被复用到 window / tray / image） | 修生成器模板 |
| 枚举魔数 | `NATIVE_DISPLAY_ORIENTATION_LANDSCAPE = 90` 继承自 C++ | 修 C++ 枚举（[api-style.md](api-style.md) §3.1） |

## 8. 检查单

- [ ] 没有手工编辑带 AUTO-GENERATED 横幅的文件。
- [ ] 新模块已加入 `API_HEADERS`，并跑过 `./codegen`。
- [ ] 新类型的归属明确（身份对象 → 句柄，值对象 → struct）。
- [ ] 身份对象已在 `IdTypeTag` 注册表登记（句柄表的类型校验依赖它）。
- [ ] 返回字符串的函数已在文档里写明由 `free_c_str()` 释放。
- [ ] 返回列表的函数已说明该配 `_list_free` 还是 `_list_release`。
- [ ] 新增的回调持有方式能保证：调用期间回调不析构，放手时析构（`user_data` 才会被释放，§6.1）。
- [ ] 改动经 `./codegen sync` 传播到三个绑定（见 workspace `AGENTS.md`）。
