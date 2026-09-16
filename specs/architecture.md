# 架构规范：分层与代码组织

> 状态：已实施
> 适用范围：`core/` 仓库全部源码
> 核实基准：2026-08-25，`core/src`（25 个公共头 + 12 个 foundation 头 + 6 个平台目录 + 28 个 capi 头）

本规范回答：**一段新代码应该放在哪一层、哪个目录、叫什么名字。**
类型的语义归属见 [object-model.md](object-model.md)，平台代码怎么写见
[platform-seam.md](platform-seam.md)。

## 1. 四层结构

```
include/nativeapi.h    单一公共入口
src/
├── foundation/        底座：不依赖上层，也不含平台分支
├── *.h / *.cpp        跨平台接口层：公共 API 的唯一定义处
├── platform/<os>/     平台实现层：接口层的六份实现
└── capi/              C ABI 层：由 codegen 生成
```

依赖方向严格自上而下，**不得反向**：`foundation/` 不引用接口层，接口层不引用
`platform/`（平台代码通过接缝被链接进来，见 platform-seam.md），`capi/` 只引用接口层。

### 1.1 foundation 层

12 个头文件，全部与平台无关，是其余各层的公共词汇表：

| 文件 | 职责 | 规范 |
|---|---|---|
| `event.h` / `event_emitter.h` | 事件基类与发射器 | [event-system.md](event-system.md) |
| `handle_table.h` | 世代句柄表，C ABI 引用生命周期 | [handle-ownership.md](handle-ownership.md) |
| `id_allocator.h` | 类型化整数 ID 分配 + `IdTypeTag` 注册表 | [object-model.md](object-model.md) |
| `object_registry.h` | `TId → shared_ptr<TObject>` 的加锁容器模板 | [managers.md](managers.md) |
| `native_object_provider.h` | 暴露平台原生句柄的基类 | [platform-seam.md](platform-seam.md) |
| `dispatcher.h`（+ `dispatcher_common.h` / `dispatcher_platform.h` 内部拆分） | 主线程投递（`RunOnMainThread`） | [event-system.md](event-system.md) §3.2 |
| `geometry.h` / `color.h` | 值类型 | [object-model.md](object-model.md) |
| `keyboard.h` | 键盘值类型，另含 `KeyboardEvent` 层级（层级放这里是历史遗留） | [event-system.md](event-system.md) |

新增 foundation 文件的门槛：**被两层以上使用，且不含任何平台分支**。只有一个消费者
的工具函数放在消费者旁边。

### 1.2 接口层

`src/*.h` 是公共 API 的**唯一**定义处。平台实现不得新增公共类型，也不得改变签名。

### 1.3 平台层

见第 2 节与 [platform-seam.md](platform-seam.md)。

### 1.4 C ABI 层

`src/capi/` 28 个头中 27 个、27 个实现中 26 个带 `// AUTO-GENERATED. DO NOT EDIT.`
横幅。**手工编辑会在下次生成时丢失。** 详见 [c-abi.md](c-abi.md)。

## 2. 平台矩阵

六个平台，`src/CMakeLists.txt` 每次构建**只选一个**目录：

| 目录 | 选择条件 | 扩展名 | 链接 |
|---|---|---|---|
| `windows/` | `WIN32` | `.cpp` | user32 shell32 dwmapi gdiplus crypt32 advapi32 version |
| `macos/` | `APPLE` | `.mm` | Cocoa、Carbon、ServiceManagement |
| `linux/` | `CMAKE_SYSTEM_NAME STREQUAL "Linux"` | `.cpp` | GTK 3.0、X11、XI、pthread |
| `android/` | `ANDROID` | `.cpp` | log、android |
| `ios/` | `CMAKE_SYSTEM_NAME STREQUAL "iOS"` | `.mm` | UIKit、Foundation、CoreGraphics |
| `ohos/` | `CMAKE_SYSTEM_NAME STREQUAL "OHOS"` | `.cpp` | hilog_ndk |

分支顺序有讲究：`ANDROID` 和 `iOS` 判断必须排在 `APPLE` / 通用分支之前，否则会落到
桌面实现上。最后的 `else()` 分支**不编译任何平台源码**——新平台在接上之前，整个库
只剩接口层符号，链接期才报错。

### 2.1 模块完整性不变量

六个平台目录当前各实现同一组约 20 个模块（`window`、`window_manager`、`display`、
`display_manager`、`menu`、`tray_icon`、`tray_manager`、`keyboard_monitor`、
`shortcut_manager`、`preferences`、`secure_storage`、`launch_at_login`、
`message_dialog`、`url_opener`、`app_info`、`device_info`、`application`、
`accessibility_manager`、`image`、`dispatcher`，以及 2026-09-16 加入的
`window_drag_session`）。

**新增一个跨平台模块，就是新增六个文件。** 少一个，那个平台链接失败——这是编译期
错误而非静默降级，不必额外防护，但要在提交前意识到工作量。

平台专属的辅助文件不受此约束（`windows/dpi_utils`、`windows/string_utils`、
`windows/window_message_dispatcher`、`macos/coordinate_utils`）。

## 3. 命名约定

### C++

| 对象 | 约定 | 例 |
|---|---|---|
| 类 / 方法 | PascalCase | `WindowManager`、`GetSize()` |
| 成员变量 | snake_case + 尾下划线 | `window_id_`、`pimpl_` |
| 枚举 | 类型与值均 PascalCase | `MenuItemType::Checkbox` |
| 文件 | snake_case | `window_manager.h` |
| 平台实现文件 | `<模块>_<平台>.<ext>` | `window_macos.mm` |

### C ABI

由生成器统一产出，人工不决定，仅供阅读时对照：

| 对象 | 约定 | 例 |
|---|---|---|
| 句柄类型 | `native_<类型>_t`（`uint64_t`） | `native_window_t` |
| ID 类型 | `native_<类型>_id_t`（`unsigned int`） | `native_window_id_t` |
| 函数 | `native_<模块>_<动作>` | `native_window_manager_get_current` |
| 枚举值 | `NATIVE_` 前缀 + SCREAMING_SNAKE | `NATIVE_DISPLAY_EVENT_TYPE_ADDED` |
| 文件 | `<模块>_c.h` / `<模块>_c.cpp` | `window_manager_c.h` |

## 4. 构建

- C++17，通过 `target_compile_features(nativeapi PUBLIC cxx_std_17)` 传播给消费者。
  这条是 PUBLIC 而非目录作用域变量——早期版本用后者，导致 tests/examples 以工具链
  默认标准编译，头文件里的 `std::optional` 编译失败。
- 静态库 `nativeapi`，公共包含目录只有 `include/`。
- `examples/` 下 23 个示例是事实上的集成测试。命名 `<模块>_example` 走 C++ API，
  `<模块>_c_example` 走 C ABI；覆盖并不完整（`window_manager`、`tray_manager`、
  `image`、`secure_storage` 等目前没有对应示例）。改动公共 API 后至少构建相关示例。

## 5. 新增模块检查单

- [ ] 类型归属：身份对象还是值对象（[object-model.md](object-model.md)）？
- [ ] 接口层建 `src/<模块>.h`（+ 必要的 `.cpp` 共享逻辑）。
- [ ] 选定平台接缝形态（[platform-seam.md](platform-seam.md)）。
- [ ] 六个平台目录各建一个实现文件，未支持的平台也要留桩。
- [ ] 身份对象：在 `foundation/id_allocator.h` 的 `IdTypeTag` 注册表**追加**条目
      （当前 13 条，只可追加不可改号）。
- [ ] 需要跨 ABI：把头文件加入 `tools/codegen/shared/src/lib.rs` 的 `API_HEADERS`
      （当前 34 条），然后 `./codegen`，不要手写 `capi/`。
- [ ] 加 `examples/<模块>_example/`。
