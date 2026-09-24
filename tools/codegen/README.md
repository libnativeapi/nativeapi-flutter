# codegen

从 C++ 头文件自动生成 **C ABI** 以及 **Rust / Dart / C#** 各端 FFI 绑定的代码生成工具。

## 工作流程

```
┌──────────────┐   ┌──────────────────────┐   ┌────────────┐   ┌──────────────────┐
│  C++ Header  │──→│     codegen-capi     │──→│  IR (JSON) │──→│ codegen-bindings │
│   (core/src) │   │  libclang 解析 + IR   │   │            │   │  rust/dart/cs    │
│              │   │  生成 C ABI + 伞头文件 │   │            │   │                  │
└──────────────┘   └──────────────────────┘   └────────────┘   └──────────────────┘
```

只有 `codegen-capi` 依赖 libclang；`codegen-bindings` 消费它导出的 IR JSON。

生成 Dart bindings 时需要 `dart` 在 PATH 中。生成器在写入和只读校验前都执行
`dart format`，使用与 Flutter 包一致的 Dart 3.9 语言版本，避免生成后再次触发
Flutter CI 的格式检查失败。Windows 上请将 Flutter SDK 的 `bin/cache/dart-sdk/bin`
加入 PATH。

## Crate 布局

```
tools/codegen/
├── Cargo.toml    # Cargo workspace
├── shared/       # codegen-shared：parser（libclang）、IR 模型与序列化、
│                 #   naming（命名工具 + 跨头文件类型索引）、文件写入/校验、API_HEADERS 清单
├── capi/         # codegen-capi（bin）：C API（.h + .cpp）与 umbrella header 生成
└── bindings/     # codegen-bindings（bin）：Rust / Dart / C# FFI 绑定生成
```

## 运行

日常统一通过 workspace 根目录的 `./codegen` 脚本执行（它负责按 workspace 布局
传路径并串联两个 generator）：

```bash
./codegen                    # 全量：C ABI → 三端绑定
./codegen capi               # 只生成 C ABI
./codegen bindings           # 只生成绑定（--lang rust,dart,csharp 可选子集）
./codegen check              # 只读校验，生成物过期时非零退出（给 CI 用）
./codegen sync               # 改完 core 后的一键联动（见下）
./codegen --dump-ir ir.json  # 把中间 IR 保留到指定路径调试
```

### `./codegen sync`：core 改动的一键下游联动

改了 core 的头文件后执行，按序完成：

1. 全量重新生成（C ABI + 三端绑定）
2. 提交 core（消息用 `-m` 指定，默认 `Update API`）
3. 对每个 binding 仓库：把内嵌的 core submodule（`cxx_impl`）
   更新到 core 的最新提交（从本地 core 取，不要求先 push）；rust 额外重跑
   bindgen 刷新 `crates/cnativeapi/src/bindings.rs`；flutter 额外执行仓库自带的
   `codegen.py`（.mm include、umbrella header、ffigen.yaml、dart ffigen）
4. 有变化的 binding 仓库各提交一个 `Sync with core <sha>`
5. 提交 workspace 的 submodule 指针

默认只提交不推送；`--push` 会按 core → bindings → workspace 的顺序推送
（保证远端的 submodule 指针不悬空）。任一仓库处于 detached HEAD 会直接报错。
bindgen / dart 未安装时对应步骤跳过并告警。

未初始化的 binding submodule 会被自动跳过，此时照常产出完整的 C ABI。

生成产物：

1. C ABI → `core/src/capi/`
2. umbrella header → `core/include/nativeapi.h`
3. Rust FFI → `bindings/rust/crates/nativeapi/src/`
5. Dart FFI → `bindings/flutter/packages/nativeapi/lib/src/`
6. C# FFI → `bindings/csharp/src/CNativeAPI/generated/`（raw 层）+ `bindings/csharp/src/NativeAPI/`（公开层）

`core/src/capi/` **全部由本工具生成**，唯一的例外是手写支持层
`string_utils_c.{h,cpp}`（字符串 / 值容器的所有权原语）。生成物首行都带
`// AUTO-GENERATED. DO NOT EDIT.`，改头文件再重新生成，不要改生成物。
没有该 banner 的已存在文件永远不会被覆盖（保护手写代码）。

要纳入生成的头文件清单 `API_HEADERS` 定义在 `shared/src/lib.rs`。

## 生成之后（必要的手工步骤）

C ABI 是所有绑定的地基，新增符号后需要同步下游：

1. **类型标签**：新增的句柄类型需要在 `core/src/foundation/id_allocator.h`
   的 `IdTypeTag<T>` 注册表里追加一个编号（**只追加，不改已有编号**）。漏了会在
   编译期报错，不会静默出问题。
2. **submodule**：`bindings/rust/crates/cnativeapi/cxx_impl`、
   `bindings/flutter/packages/cnativeapi/cxx_impl`、`bindings/csharp/src/CNativeAPI/cxx_impl`
   都是 nativeapi 仓库的 submodule，提交 core 后需要 `git submodule update --remote`
3. **Rust raw FFI**：`crates/cnativeapi/src/bindings.rs` 由 bindgen 生成并入库，
   新增 C 符号后需重新生成（在 workspace 根目录执行）：

   ```bash
   bindgen core/include/nativeapi.h \
     --allowlist-function 'native_.*|free_c_str' --allowlist-type 'native_.*' \
     --allowlist-var 'NATIVE_.*' \
     --with-derive-default --no-layout-tests --no-prepend-enum-name \
     --raw-line '#![allow(non_upper_case_globals)]' \
     --raw-line '#![allow(non_camel_case_types)]' \
     --raw-line '#![allow(non_snake_case)]' \
     -o bindings/rust/crates/cnativeapi/src/bindings.rs \
     -- -x c -isysroot "$(xcrun --show-sdk-path)" -Icore/src -Icore/include
   ```

4. **模块声明**：Rust 侧新增的 `xxx.rs` 需要在 `crates/nativeapi/src/lib.rs` 中 `pub mod`
