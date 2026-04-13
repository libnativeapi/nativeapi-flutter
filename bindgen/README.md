# Flutter Wrapper Bindgen

This bindgen setup generates Dart wrapper files from C++ API headers.

- Input: `cxx_impl/src/**/*.h` (excluding `capi` and `platform`)
- Output: `bindgen/out/**/*.dart`
- FFI policy: wrappers call existing `CNativeApiBindings` methods from ffigen output

## Run

```bash
cd nativeapi-flutter
PYTHONPATH=packages/cnativeapi/cxx_impl/tools python3 -m bindgen \
  --config bindgen/config.yaml \
  --dump-ir bindgen/out/ir.json \
  --dump-context bindgen/out/context.json \
  --out bindgen/out
```

## Notes

- This does **not** regenerate `lib/src/bindings_generated.dart`.
- Add symbol exceptions in `mapping.options.symbol_overrides`.
- `bindgen/out/context.json` is the mapped template input after IR -> API/config transformation.
