# Rust Wrapper Bindgen

This bindgen setup generates Rust API wrapper files from C++ headers.

- Input: C++ headers under `crates/cnativeapi/cxx_impl/src` (excluding `capi` and `platform`)
- Output: Rust wrapper files under `bindgen/out/**`
- FFI policy: wrappers call existing C API symbols from `crate::bindings` only

## Run

```bash
cd nativeapi-rust
PYTHONPATH=crates/cnativeapi/cxx_impl/tools python3 -m bindgen \
  --config bindgen/config.yaml \
  --dump-ir bindgen/out/ir.json \
  --out bindgen/out
```

## Template Structure

```text
bindgen/template/
  file/
    rs.j2                  # Per-file orchestration template
  partials/
    type_map.j2            # Rust type mapping helpers
    symbol_map.j2          # C++ -> CAPI symbol mapping helpers
    function.j2            # Free-function wrapper rendering
    class.j2               # Class wrapper rendering
```

## Notes

- This generation does **not** update `crates/cnativeapi/src/bindings.rs`.
- If a C++ symbol does not map cleanly to a C API symbol, add override entries in:
  - `mapping.options.symbol_overrides`
