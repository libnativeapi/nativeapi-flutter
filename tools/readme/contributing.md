## Contributing

Development happens in [nativeapi-workspace](https://github.com/libnativeapi/nativeapi-workspace), which holds every binding and the code generator and checks out the core library as a submodule:

```bash
git clone --recursive https://github.com/libnativeapi/nativeapi-workspace.git
```

Files marked `AUTO-GENERATED. DO NOT EDIT.` are generated from the C++ headers in [nativeapi](https://github.com/libnativeapi/nativeapi-core). To change the API, send a pull request there; maintainers regenerate the bindings.

- API requests and native behavior bugs → [nativeapi-core issues](https://github.com/libnativeapi/nativeapi-core/issues)
- Bugs specific to one binding → [nativeapi-workspace issues](https://github.com/libnativeapi/nativeapi-workspace/issues)
- Not sure → [nativeapi-core issues](https://github.com/libnativeapi/nativeapi-core/issues)
