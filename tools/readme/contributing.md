## Contributing

This repository is developed from the [nativeapi-workspace](https://github.com/libnativeapi/nativeapi-workspace), which checks out the core library, every binding and the code generator together:

```bash
git clone --recursive https://github.com/libnativeapi/nativeapi-workspace.git
```

Files marked `AUTO-GENERATED. DO NOT EDIT.` are generated from the C++ headers in [nativeapi](https://github.com/libnativeapi/nativeapi). To change the API, send a pull request there; maintainers regenerate the bindings.

- API requests and native behavior bugs → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)
- Bugs specific to one binding → that binding's repository
- Not sure → [nativeapi issues](https://github.com/libnativeapi/nativeapi/issues)
