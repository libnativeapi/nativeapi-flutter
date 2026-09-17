## 参与贡献

本仓库在 [workspace](https://github.com/libnativeapi/workspace) 中开发，它把核心库、所有绑定和代码生成器放在一起：

```bash
git clone --recursive https://github.com/libnativeapi/workspace.git
```

标有 `AUTO-GENERATED. DO NOT EDIT.` 的文件由 [nativeapi](https://github.com/libnativeapi/nativeapi) 的 C++ 头文件生成。如需修改 API，请向该仓库提交 PR，绑定由维护者重新生成。

- API 需求、原生行为问题 → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)
- 仅影响某个绑定的问题 → 对应绑定的仓库
- 不确定 → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)
