## 参与贡献

开发在 [nativeapi-workspace](https://github.com/libnativeapi/nativeapi-workspace) 中进行，它包含所有绑定和代码生成器，并以 submodule 的形式检出核心库：

```bash
git clone --recursive https://github.com/libnativeapi/nativeapi-workspace.git
```

标有 `AUTO-GENERATED. DO NOT EDIT.` 的文件由 [nativeapi](https://github.com/libnativeapi/nativeapi) 的 C++ 头文件生成。如需修改 API，请向该仓库提交 PR，绑定由维护者重新生成。

- API 需求、原生行为问题 → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)
- 仅影响某个绑定的问题 → [nativeapi-workspace issues](https://github.com/libnativeapi/nativeapi-workspace/issues)
- 不确定 → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)
