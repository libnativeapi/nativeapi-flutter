use std::fmt::Write;
use std::path::{Path, PathBuf};

use heck::{ToLowerCamelCase, ToSnakeCase, ToUpperCamelCase};

use codegen_shared::naming::{
    c_add_listener_symbol, c_constructor_symbol, c_event_variant,
    c_event_variant_field, c_free_symbol, c_list_field, c_list_release_symbol, c_method_symbol,
    c_native_object_symbol, c_remove_listener_symbol, c_type_name, constructor_suffix,
    foreign_types, is_binding_accessor, struct_has_owned_fields, swift_method_name, TypeOrigins,
    STRING_FREE_FN, STRING_LIST_FREE_FN, STRING_MAP_FREE_FN,
};
use codegen_shared::GeneratedFile;
use codegen_shared::ir::{Api, Class, Constructor, Enum, EventGroup, Header, Method, Param, Struct, TypeRef};

/// Alias for the raw ffigen bindings inside every generated file.
const C: &str = "c";

/// Structs that `dart:ui` already provides, and how to convert them.
///
/// Generating our own `Color` and `Size` would collide with the ones every
/// Flutter app already has: `Colors.blue` is a `MaterialColor`, which is a
/// `dart:ui` `Color` and not ours, so the two cannot meet. Reusing the host
/// types also means a caller can pass an `Offset` straight from a gesture
/// callback instead of converting first.
///
/// Tuple: C++ struct name, Dart type, how to build it from the raw struct
/// (`{}` is the raw expression), and how each C field is read back out of the
/// Dart value (`{}` is the Dart expression).
const HOST_TYPES: &[(&str, &str, &str, &[(&str, &str)])] = &[
    ("Point", "Offset", "Offset({}.x, {}.y)", &[("x", "{}.dx"), ("y", "{}.dy")]),
    (
        "Size",
        "Size",
        "Size({}.width, {}.height)",
        &[("width", "{}.width"), ("height", "{}.height")],
    ),
    (
        "Rectangle",
        "Rect",
        "Rect.fromLTWH({}.x, {}.y, {}.width, {}.height)",
        &[
            ("x", "{}.left"),
            ("y", "{}.top"),
            ("width", "{}.width"),
            ("height", "{}.height"),
        ],
    ),
    (
        "Color",
        "Color",
        "Color.fromARGB({}.a, {}.r, {}.g, {}.b)",
        &[
            // Flutter's components are doubles in 0..1; the C ABI wants bytes.
            ("r", "({}.r * 255).round()"),
            ("g", "({}.g * 255).round()"),
            ("b", "({}.b * 255).round()"),
            ("a", "({}.a * 255).round()"),
        ],
    ),
];

struct HostType {
    dart: &'static str,
    from_raw: &'static str,
    fields: &'static [(&'static str, &'static str)],
}

fn host_type(name: &str) -> Option<HostType> {
    HOST_TYPES
        .iter()
        .find(|(cpp, ..)| *cpp == name)
        .map(|(_, dart, from_raw, fields)| HostType {
            dart,
            from_raw,
            fields,
        })
}

/// Substitutes every `{}` in a template with the same expression.
fn fill(template: &str, value: &str) -> String {
    template.replace("{}", value)
}

/// ffigen's header list, which has to name every generated `*_c.h`. Keeping it
/// hand-written meant it silently drifted: `placement_c.h` was missing from it
/// even though the module existed.
pub fn generate_ffigen_config(api: &Api, cnativeapi_root: &Path) -> GeneratedFile {
    let mut out = String::new();
    writeln!(out, "# AUTO-GENERATED. DO NOT EDIT.").unwrap();
    writeln!(
        out,
        "# Any manual changes WILL BE LOST when this file is regenerated."
    )
    .unwrap();
    writeln!(out, "#").unwrap();
    writeln!(out, "# Run with `dart run ffigen --config ffigen.yaml`.").unwrap();
    writeln!(out, "name: CNativeApiBindings").unwrap();
    writeln!(out, "description: |").unwrap();
    writeln!(out, "  Bindings for `nativeapi capi`.").unwrap();
    writeln!(out, "output: \"lib/src/bindings_generated.dart\"").unwrap();

    let mut headers: Vec<String> = api
        .headers
        .iter()
        .map(|header| format!("cxx_impl/src/capi/{}_c.h", header.stem))
        .collect();
    headers.push("cxx_impl/src/capi/common_c.h".to_string());
    headers.push("cxx_impl/src/capi/string_utils_c.h".to_string());
    headers.sort();

    writeln!(out, "headers:").unwrap();
    writeln!(out, "  entry-points:").unwrap();
    for header in &headers {
        writeln!(out, "    - \"{header}\"").unwrap();
    }
    writeln!(out).unwrap();
    writeln!(out, "  include-directives:").unwrap();
    for header in &headers {
        writeln!(out, "    - \"{header}\"").unwrap();
    }
    writeln!(out).unwrap();
    writeln!(out, "preamble: |").unwrap();
    writeln!(out, "  // ignore_for_file: always_specify_types").unwrap();
    writeln!(out, "  // ignore_for_file: camel_case_types").unwrap();
    writeln!(out, "  // ignore_for_file: non_constant_identifier_names").unwrap();
    writeln!(out, "comments:").unwrap();
    writeln!(out, "  style: any").unwrap();
    writeln!(out, "  length: full").unwrap();
    writeln!(out, "silence-enum-warning: true").unwrap();
    writeln!(out, "ignore-source-errors: true").unwrap();

    GeneratedFile {
        path: cnativeapi_root.join("ffigen.yaml"),
        contents: out,
    }
}

pub fn generate(
    api: &Api,
    header: &Header,
    origins: &TypeOrigins,
    dart_out: &Path,
    prefix: &str,
) -> GeneratedFile {
    GeneratedFile {
        path: dart_out.join(dart_relative_path(header)),
        contents: generate_dart(api, header, origins, prefix),
    }
}

/// Definitions shared by every generated module. Dart re-exports collide on a
/// duplicated name, so `ListenerId` can only be declared once.
pub fn generate_support(dart_out: &Path) -> GeneratedFile {
    let mut out = String::new();
    write_banner(&mut out);
    writeln!(out, "/// Identifies one registered event listener.").unwrap();
    writeln!(out, "typedef ListenerId = int;").unwrap();
    GeneratedFile {
        path: dart_out.join("support.dart"),
        contents: out,
    }
}

/// The barrel of generated modules. `lib/nativeapi.dart` stays hand-written —
/// it also exports the hand-written widgets — and re-exports this.
pub fn generate_barrel(api: &Api, dart_out: &Path) -> GeneratedFile {
    let mut out = String::new();
    write_banner(&mut out);
    let mut paths: Vec<String> = api
        .headers
        .iter()
        .map(|header| dart_relative_path(header).to_string_lossy().replace('\\', "/"))
        .collect();
    paths.push("support.dart".to_string());
    paths.sort();
    for path in paths {
        writeln!(out, "export '{path}';").unwrap();
    }
    GeneratedFile {
        path: dart_out.join("generated.dart"),
        contents: out,
    }
}

/// `foundation/geometry.h` -> `foundation/geometry.dart`, mirroring the source
/// tree the way the Rust and Swift outputs do.
fn dart_relative_path(header: &Header) -> PathBuf {
    let mut path = PathBuf::new();
    if let Some(parent) = header.path.parent().and_then(|p| p.file_name()) {
        let parent = parent.to_string_lossy().to_string();
        if parent == "foundation" {
            path.push(parent);
        }
    }
    path.join(format!("{}.dart", header.stem))
}

fn write_banner(out: &mut String) {
    writeln!(out, "// AUTO-GENERATED. DO NOT EDIT.").unwrap();
    writeln!(
        out,
        "// Any manual changes WILL BE LOST when this file is regenerated."
    )
    .unwrap();
    writeln!(out).unwrap();
}

fn generate_dart(api: &Api, header: &Header, origins: &TypeOrigins, prefix: &str) -> String {
    let mut out = String::new();
    write_banner(&mut out);
    writeln!(out, "// ignore_for_file: unused_import, unnecessary_import").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "import 'dart:ffi' as ffi;").unwrap();
    writeln!(out, "import 'dart:ui';").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "import 'package:cnativeapi/cnativeapi.dart' as {C};").unwrap();
    writeln!(out, "import 'package:ffi/ffi.dart' as pkg_ffi;").unwrap();
    writeln!(out).unwrap();

    let here = dart_relative_path(header);
    let deps: Vec<String> = foreign_types(header, origins)
        .into_iter()
        .filter_map(|name| origins.get(&name).cloned())
        .filter(|stem| stem != &header.stem)
        .collect();
    let mut imports: Vec<String> = deps
        .into_iter()
        .filter_map(|stem| {
            let other = api.headers.iter().find(|h| h.stem == stem)?;
            Some(dart_import_path(&here, &dart_relative_path(other)))
        })
        .collect();
    imports.sort();
    imports.dedup();
    if !imports.is_empty() {
        for import in &imports {
            writeln!(out, "import '{import}';").unwrap();
        }
        writeln!(out).unwrap();
    }

    if header.classes.iter().any(|class| class.event.is_some()) {
        writeln!(
            out,
            "import '{}';",
            dart_import_path(&here, Path::new("support.dart"))
        )
        .unwrap();
        writeln!(out).unwrap();
    }

    let prelude = std::mem::take(&mut out);

    for alias in &header.aliases {
        if origins.get(&alias.name).map(String::as_str) != Some(header.stem.as_str()) {
            continue;
        }
        writeln!(out, "typedef {} = int;", alias.name).unwrap();
        writeln!(out).unwrap();
    }

    for item in &header.enums {
        render_dart_enum(&mut out, item, prefix);
    }

    for item in &header.structs {
        if host_type(&item.name).is_some() {
            continue;
        }
        render_dart_struct(&mut out, item, prefix);
    }

    for group in &header.events {
        render_dart_event(&mut out, group, prefix);
    }

    let mut body = String::new();
    for class in &header.classes {
        render_dart_class(&mut body, api, header, class, prefix);
    }

    // An enum- or struct-only module never reaches the C side.
    let mut declarations = String::new();
    if out.contains("_bindings.") || body.contains("_bindings.") {
        writeln!(declarations, "final _bindings = {C}.cnativeApiBindings;").unwrap();
        writeln!(declarations).unwrap();
    }

    format!("{prelude}{declarations}{out}{body}")
}

/// A relative import from one generated file to another.
fn dart_import_path(from: &Path, to: &Path) -> String {
    let from_dir = from.parent().unwrap_or(Path::new(""));
    let to_dir = to.parent().unwrap_or(Path::new(""));
    let name = to.file_name().unwrap_or_default().to_string_lossy();
    if from_dir == to_dir {
        return name.to_string();
    }
    if from_dir.as_os_str().is_empty() {
        return format!("{}/{name}", to_dir.to_string_lossy().replace('\\', "/"));
    }
    if to_dir.as_os_str().is_empty() {
        return format!("../{name}");
    }
    format!("../{}/{name}", to_dir.to_string_lossy().replace('\\', "/"))
}

// ---------------------------------------------------------------------------
// Enums and structs
// ---------------------------------------------------------------------------

fn render_dart_enum(out: &mut String, item: &Enum, prefix: &str) {
    let c_ty = format!("{C}.{}", c_type_name(prefix, &item.name));
    writeln!(out, "enum {} {{", item.name).unwrap();
    for (index, variant) in item.variants.iter().enumerate() {
        let sep = if index + 1 == item.variants.len() {
            ";"
        } else {
            ","
        };
        writeln!(
            out,
            "  {}({}){sep}",
            dart_enum_case(&variant.name),
            variant.value
        )
        .unwrap();
    }
    writeln!(out).unwrap();
    writeln!(out, "  const {}(this.value);", item.name).unwrap();
    writeln!(out, "  final int value;").unwrap();
    writeln!(out).unwrap();
    let fallback = item
        .variants
        .first()
        .map(|variant| dart_enum_case(&variant.name))
        .unwrap_or_else(|| "unknown".to_string());
    writeln!(out, "  static {} fromValue(int value) => switch (value) {{", item.name).unwrap();
    for variant in &item.variants {
        writeln!(
            out,
            "    {} => {}.{},",
            variant.value,
            item.name,
            dart_enum_case(&variant.name)
        )
        .unwrap();
    }
    writeln!(out, "    _ => {}.{fallback},", item.name).unwrap();
    writeln!(out, "  }};").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "  {c_ty} get raw => {c_ty}.fromValue(value);").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

fn render_dart_struct(out: &mut String, item: &Struct, prefix: &str) {
    let c_ty = format!("{C}.{}", c_type_name(prefix, &item.name));
    writeln!(out, "class {} {{", item.name).unwrap();
    write!(out, "  const {}({{", item.name).unwrap();
    for field in &item.fields {
        if is_callback(&field.ty) {
            write!(out, "this.{}, ", field.name.to_lower_camel_case()).unwrap();
        } else {
            write!(out, "required this.{}, ", field.name.to_lower_camel_case()).unwrap();
        }
    }
    writeln!(out, "}});").unwrap();
    writeln!(out).unwrap();
    for field in &item.fields {
        writeln!(
            out,
            "  final {} {};",
            dart_field_type(&field.ty),
            field.name.to_lower_camel_case()
        )
        .unwrap();
    }
    writeln!(out).unwrap();

    writeln!(out, "  factory {}.fromNative({c_ty} raw) => {}(", item.name, item.name).unwrap();
    for field in &item.fields {
        let name = field.name.to_lower_camel_case();
        if is_callback(&field.ty) {
            continue;
        }
        writeln!(
            out,
            "    {name}: {},",
            dart_from_native(&field.ty, &format!("raw.{}", field.name.to_snake_case()))
        )
        .unwrap();
    }
    writeln!(out, "  );").unwrap();
    writeln!(out).unwrap();

    // An ffi.Struct cannot exist off-heap in Dart, so anything passing one by
    // value has to allocate it first and free it after the call.
    writeln!(out, "  /// Allocates the C form; free it with [freeNative].").unwrap();
    writeln!(out, "  ffi.Pointer<{c_ty}> allocNative() {{").unwrap();
    writeln!(out, "    final pointer = pkg_ffi.calloc<{c_ty}>();").unwrap();
    for field in &item.fields {
        let name = field.name.to_lower_camel_case();
        let raw = field.name.to_snake_case();
        match &field.ty {
            TypeRef::String | TypeRef::CString => {
                writeln!(
                    out,
                    "    pointer.ref.{raw} = {name} == null\n        ? ffi.nullptr\n        : {name}!.toNativeUtf8().cast<ffi.Char>();"
                )
                .unwrap();
            }
            TypeRef::Enum { .. } => {
                writeln!(out, "    pointer.ref.{raw} = {name}.value;").unwrap();
            }
            TypeRef::Struct { .. } => {
                writeln!(out, "    final {name}Pointer = {name}.allocNative();").unwrap();
                writeln!(out, "    pointer.ref.{raw} = {name}Pointer.ref;").unwrap();
                writeln!(out, "    pkg_ffi.calloc.free({name}Pointer);").unwrap();
            }
            TypeRef::Callback { .. } => {
                writeln!(
                    out,
                    "    // Callback fields are installed by the caller; see the setters."
                )
                .unwrap();
            }
            _ => {
                writeln!(out, "    pointer.ref.{raw} = {name};").unwrap();
            }
        }
    }
    writeln!(out, "    return pointer;").unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out).unwrap();
    writeln!(
        out,
        "  static void freeNative(ffi.Pointer<{c_ty}> pointer) {{"
    )
    .unwrap();
    if struct_has_owned_fields(item) {
        for field in &item.fields {
            if matches!(field.ty, TypeRef::String | TypeRef::CString) {
                let raw = field.name.to_snake_case();
                writeln!(out, "    if (pointer.ref.{raw} != ffi.nullptr) {{").unwrap();
                writeln!(
                    out,
                    "      pkg_ffi.calloc.free(pointer.ref.{raw});"
                )
                .unwrap();
                writeln!(out, "    }}").unwrap();
            }
        }
    }
    writeln!(out, "    pkg_ffi.calloc.free(pointer);").unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

fn render_dart_event(out: &mut String, group: &EventGroup, prefix: &str) {
    let c_ty = format!("{C}.{}", c_type_name(prefix, &group.name));
    let type_enum = format!("{C}.{}", codegen_shared::naming::c_event_type_enum(prefix, &group.name));

    writeln!(out, "/// One `{}`, in its concrete form.", group.name).unwrap();
    writeln!(out, "sealed class {} {{", group.name).unwrap();
    writeln!(out, "  const {}();", group.name).unwrap();
    writeln!(out).unwrap();
    // What every variant carries can be read without matching the variant.
    for field in &group.common {
        writeln!(
            out,
            "  {} get {};",
            dart_event_field_type(&field.ty),
            field.name.to_lower_camel_case()
        )
        .unwrap();
    }
    if !group.common.is_empty() {
        writeln!(out).unwrap();
    }
    writeln!(
        out,
        "  /// Reads the event out of its C form. Returns null for a variant this"
    )
    .unwrap();
    writeln!(out, "  /// binding does not know about.").unwrap();
    writeln!(out, "  static {}? fromNative({c_ty} raw) {{", group.name).unwrap();
    for variant in &group.variants {
        let payload = c_event_variant_field(&variant.discriminant);
        let mut args: Vec<String> = Vec::new();
        for field in &group.common {
            args.push(format!(
                "{}: {}",
                field.name.to_lower_camel_case(),
                dart_from_native(&field.ty, &format!("raw.{}", field.name.to_snake_case()))
            ));
        }
        for field in &variant.fields {
            args.push(format!(
                "{}: {}",
                field.name.to_lower_camel_case(),
                dart_from_native(
                    &field.ty,
                    &format!("raw.data.{payload}.{}", field.name.to_snake_case())
                )
            ));
        }
        writeln!(
            out,
            "    if (raw.type == {type_enum}.{}.value) {{",
            c_event_variant(prefix, &group.name, &variant.discriminant)
        )
        .unwrap();
        writeln!(
            out,
            "      return {}({});",
            event_variant_class(group, variant.discriminant.as_str()),
            args.join(", ")
        )
        .unwrap();
        writeln!(out, "    }}").unwrap();
    }
    writeln!(out, "    return null;").unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    for variant in &group.variants {
        let class_name = event_variant_class(group, &variant.discriminant);
        let fields: Vec<&codegen_shared::ir::Field> =
            group.common.iter().chain(variant.fields.iter()).collect();
        writeln!(out, "final class {class_name} extends {} {{", group.name).unwrap();
        write!(out, "  const {class_name}(").unwrap();
        if !fields.is_empty() {
            write!(out, "{{").unwrap();
            for field in &fields {
                write!(out, "required this.{}, ", field.name.to_lower_camel_case()).unwrap();
            }
            write!(out, "}}").unwrap();
        }
        writeln!(out, ");").unwrap();
        if !fields.is_empty() {
            writeln!(out).unwrap();
        }
        for (index, field) in fields.iter().enumerate() {
            if index < group.common.len() {
                writeln!(out, "  @override").unwrap();
            }
            writeln!(
                out,
                "  final {} {};",
                dart_event_field_type(&field.ty),
                field.name.to_lower_camel_case()
            )
            .unwrap();
        }
        writeln!(out, "}}").unwrap();
        writeln!(out).unwrap();
    }
}

/// `WindowEvent` + `Focused` -> `WindowFocusedEvent`, matching the C++ name.
fn event_variant_class(group: &EventGroup, discriminant: &str) -> String {
    let stem = group.name.strip_suffix("Event").unwrap_or(&group.name);
    format!("{stem}{}Event", discriminant.to_upper_camel_case())
}

fn dart_event_field_type(ty: &TypeRef) -> String {
    match ty {
        TypeRef::Object { name, .. } => name.clone(),
        other => dart_field_type(other),
    }
}

// ---------------------------------------------------------------------------
// Classes
// ---------------------------------------------------------------------------

fn render_dart_class(out: &mut String, api: &Api, header: &Header, class: &Class, prefix: &str) {
    let instance = class.is_instance();
    writeln!(out, "class {} {{", class.name).unwrap();

    if instance {
        writeln!(
            out,
            "  /// Adopts a handle returned by the C API and releases it when this"
        )
        .unwrap();
        writeln!(out, "  /// object becomes unreachable.").unwrap();
        writeln!(out, "  {}.fromHandle(this.nativeHandle) {{", class.name).unwrap();
        writeln!(
            out,
            "    _finalizer.attach(this, nativeHandle, detach: this);"
        )
        .unwrap();
        writeln!(out, "  }}").unwrap();
        writeln!(out).unwrap();
        writeln!(
            out,
            "  /// Wraps a handle owned elsewhere; releasing it stays the owner's job."
        )
        .unwrap();
        writeln!(out, "  {}.borrowed(this.nativeHandle);", class.name).unwrap();
        writeln!(out).unwrap();
        writeln!(out, "  /// The underlying handle-table entry.").unwrap();
        writeln!(out, "  final int nativeHandle;").unwrap();
        writeln!(out).unwrap();
        writeln!(
            out,
            "  static final Finalizer<int> _finalizer = Finalizer<int>("
        )
        .unwrap();
        writeln!(
            out,
            "    (handle) => _bindings.{}(handle),",
            c_free_symbol(prefix, &class.name)
        )
        .unwrap();
        writeln!(out, "  );").unwrap();
        writeln!(out).unwrap();
        writeln!(out, "  /// Releases the handle now instead of at collection.").unwrap();
        writeln!(out, "  void dispose() {{").unwrap();
        writeln!(out, "    _finalizer.detach(this);").unwrap();
        writeln!(
            out,
            "    _bindings.{}(nativeHandle);",
            c_free_symbol(prefix, &class.name)
        )
        .unwrap();
        writeln!(out, "  }}").unwrap();
        writeln!(out).unwrap();
    } else {
        // Singletons surface as `.instance` rather than static namespaces so
        // they can implement interfaces and be swapped in tests.
        writeln!(out, "  const {}._();", class.name).unwrap();
        writeln!(out).unwrap();
        writeln!(
            out,
            "  /// The shared instance backed by the native singleton."
        )
        .unwrap();
        writeln!(
            out,
            "  static const {} instance = {}._();",
            class.name, class.name
        )
        .unwrap();
        writeln!(out).unwrap();
    }

    for ctor in &class.constructors {
        render_dart_constructor(out, class, ctor, prefix);
    }

    for method in &class.methods {
        render_dart_method(out, class, method, header, prefix);
    }

    if instance && class.native_object {
        writeln!(
            out,
            "  /// Platform-specific native object behind this handle."
        )
        .unwrap();
        writeln!(out, "  ffi.Pointer<ffi.Void> get nativeObject =>").unwrap();
        writeln!(
            out,
            "      _bindings.{}(nativeHandle);",
            c_native_object_symbol(prefix, &class.name)
        )
        .unwrap();
        writeln!(out).unwrap();
    }

    render_dart_listener(out, api, class, prefix);

    if emitted_group(api, class).is_none() && class_takes_callback(class) {
        writeln!(
            out,
            "  /// Trampolines stay reachable for as long as the C side may call them."
        )
        .unwrap();
        writeln!(out, "  static final List<Object> _listeners = <Object>[];").unwrap();
        writeln!(out).unwrap();
    }

    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

fn render_dart_constructor(out: &mut String, class: &Class, ctor: &Constructor, prefix: &str) {
    let label = match constructor_suffix(class, ctor) {
        Some(suffix) => format!("create{}", suffix.to_upper_camel_case()),
        None => "create".to_string(),
    };
    writeln!(
        out,
        "  /// Creates a new `{}`; returns null if the native side failed.",
        class.name
    )
    .unwrap();
    writeln!(
        out,
        "  static {}? {label}({}) {{",
        class.name,
        dart_params(&ctor.params)
    )
    .unwrap();
    render_param_bindings(out, &ctor.params, prefix, "    ");
    writeln!(
        out,
        "    final handle = _bindings.{}({});",
        c_constructor_symbol(prefix, class, ctor),
        call_args(&ctor.params, None)
    )
    .unwrap();
    render_param_cleanup(out, &ctor.params, "    ");
    writeln!(out, "    if (handle == 0) return null;").unwrap();
    writeln!(out, "    return {}.fromHandle(handle);", class.name).unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out).unwrap();
}

fn render_dart_method(
    out: &mut String,
    class: &Class,
    method: &Method,
    header: &Header,
    prefix: &str,
) {
    let instance = class.is_instance() && !method.is_static;
    let name = swift_method_name(class, method).to_lower_camel_case();
    let accessor = is_binding_accessor(class, method) && method.params.is_empty();
    // Dart spells accessors as properties, and `GetX` already becomes one; a
    // matching one-argument `SetX` has to follow or the property would be
    // readable but not writable.
    let setter = dart_setter_name(class, method);
    let return_type = dart_return_type(&method.return_type);

    if let Some(name) = &setter {
        writeln!(
            out,
            "  set {name}({} value) {{",
            dart_param_type(&method.params[0].ty)
        )
        .unwrap();
    } else if accessor {
        writeln!(out, "  {return_type} get {name} {{").unwrap();
    } else {
        // Singleton methods are instance methods on `.instance`; only a static
        // method of a handle class stays static.
        let prefix_kw = if class.is_instance() && method.is_static {
            "  static "
        } else {
            "  "
        };
        writeln!(
            out,
            "{prefix_kw}{return_type} {name}({}) {{",
            dart_params(&method.params)
        )
        .unwrap();
    }

    // The property form renames the single parameter to `value`.
    let params: Vec<Param> = if setter.is_some() {
        vec![Param {
            name: "value".to_string(),
            ty: method.params[0].ty.clone(),
        }]
    } else {
        method.params.clone()
    };
    render_param_bindings(out, &params, prefix, "    ");
    let receiver = instance.then(|| "nativeHandle".to_string());
    let call = format!(
        "_bindings.{}({})",
        c_method_symbol(prefix, class, method),
        call_args(&params, receiver)
    );
    render_return(out, &method.return_type, &call, &params, header, prefix);
    writeln!(out, "  }}").unwrap();
    writeln!(out).unwrap();
}

/// The property name a `SetX(value)` method should use, when the class also
/// exposes the matching `GetX()` as a property. Everything else stays a method:
/// a two-argument setter (`SetSize(size, animate)`) is not a property, and a
/// setter with no getter would read oddly as one.
fn dart_setter_name(class: &Class, method: &Method) -> Option<String> {
    if method.is_static || method.params.len() != 1 {
        return None;
    }
    if !matches!(method.return_type, TypeRef::Void) {
        return None;
    }
    let stem = method.name.strip_prefix("Set")?;
    // The getter may be `GetResizable` or `IsResizable`; the property takes the
    // getter's name so the pair reads as one thing.
    let getter = class.methods.iter().find(|other| {
        other.params.is_empty()
            && is_binding_accessor(class, other)
            && matches!(
                other.binding_name(),
                name if name == stem
                    || name == format!("Is{stem}")
                    || name == format!("Has{stem}")
            )
    })?;
    Some(getter.binding_name().to_lower_camel_case())
}

fn render_dart_listener(out: &mut String, api: &Api, class: &Class, prefix: &str) {
    let Some(group) = emitted_group(api, class) else {
        return;
    };
    let c_event = format!("{C}.{}", c_type_name(prefix, &group.name));
    let instance = class.is_instance();
    // Listener registration is an instance method everywhere: handle classes
    // pass their handle, singletons go through `.instance`.
    let keyword = "  ";
    let self_arg = if instance { "nativeHandle, " } else { "" };

    writeln!(
        out,
        "  /// Registers [callback] for every `{}` this `{}` emits.",
        group.name, class.name
    )
    .unwrap();
    writeln!(out, "  ///").unwrap();
    writeln!(
        out,
        "  /// The callback runs synchronously on whichever thread the native side"
    )
    .unwrap();
    writeln!(
        out,
        "  /// dispatches from, because the event struct is freed as soon as it"
    )
    .unwrap();
    writeln!(
        out,
        "  /// returns. That thread must therefore be this isolate's own; see the"
    )
    .unwrap();
    writeln!(out, "  /// package README for what that means under Flutter.").unwrap();
    writeln!(
        out,
        "{keyword}ListenerId addListener(void Function({}) callback) {{",
        group.name
    )
    .unwrap();
    writeln!(
        out,
        "    final callable = ffi.NativeCallable<\n        ffi.Void Function(ffi.Pointer<{c_event}>, ffi.Pointer<ffi.Void>)>.isolateLocal("
    )
    .unwrap();
    writeln!(out, "      (ffi.Pointer<{c_event}> event, ffi.Pointer<ffi.Void> _) {{").unwrap();
    writeln!(out, "        if (event == ffi.nullptr) return;").unwrap();
    writeln!(
        out,
        "        final value = {}.fromNative(event.ref);",
        group.name
    )
    .unwrap();
    writeln!(out, "        if (value != null) callback(value);").unwrap();
    writeln!(out, "      }},").unwrap();
    writeln!(out, "    );").unwrap();
    writeln!(
        out,
        "    _listeners.add(callable);  // keeps the trampoline alive"
    )
    .unwrap();
    writeln!(
        out,
        "    return _bindings.{}({self_arg}callable.nativeFunction, ffi.nullptr);",
        c_add_listener_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out).unwrap();

    writeln!(out, "  /// Unregisters a listener. Returns false if unknown.").unwrap();
    writeln!(
        out,
        "{keyword}bool removeListener(ListenerId listenerId) =>"
    )
    .unwrap();
    writeln!(
        out,
        "      _bindings.{}({self_arg}listenerId);",
        c_remove_listener_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(out).unwrap();
    writeln!(
        out,
        "  /// Trampolines stay reachable for as long as the C side may call them."
    )
    .unwrap();
    writeln!(out, "  static final List<Object> _listeners = <Object>[];").unwrap();
    writeln!(out).unwrap();
}

/// Whether any member of this class takes a callback, and so needs somewhere to
/// park the trampoline.
fn class_takes_callback(class: &Class) -> bool {
    class
        .methods
        .iter()
        .flat_map(|method| method.params.iter())
        .chain(class.constructors.iter().flat_map(|ctor| ctor.params.iter()))
        .any(|param| is_callback(&param.ty))
}

fn emitted_group<'a>(api: &'a Api, class: &Class) -> Option<&'a EventGroup> {
    let event = class.event.as_ref()?;
    api.headers
        .iter()
        .flat_map(|header| header.events.iter())
        .find(|group| &group.name == event)
}

// ---------------------------------------------------------------------------
// Parameters and returns
// ---------------------------------------------------------------------------

fn dart_params(params: &[Param]) -> String {
    if params.is_empty() {
        return String::new();
    }
    let rendered: Vec<String> = params
        .iter()
        .map(|param| {
            format!(
                "{} {}",
                dart_param_type(&param.ty),
                param.name.to_lower_camel_case()
            )
        })
        .collect();
    rendered.join(", ")
}

fn dart_param_type(ty: &TypeRef) -> String {
    match ty {
        TypeRef::String | TypeRef::CString => "String".to_string(),
        // A shared_ptr parameter accepts null: that is how the C++ API clears
        // an icon or detaches a submenu.
        TypeRef::Object { name, shared: true, .. } => format!("{name}?"),
        TypeRef::Object { name, .. } => name.clone(),
        TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
            "List<String>".to_string()
        }
        TypeRef::Map { .. } => "Map<String, String>".to_string(),
        TypeRef::Callback { params } => {
            format!("void Function({})", dart_callback_args(params))
        }
        TypeRef::Optional { inner } => match inner.as_ref() {
            TypeRef::Callback { params } => {
                format!("void Function({})?", dart_callback_args(params))
            }
            other => format!("{}?", dart_param_type(other)),
        },
        other => dart_field_type(other),
    }
}

fn dart_callback_args(params: &[TypeRef]) -> String {
    params
        .iter()
        .map(dart_field_type)
        .collect::<Vec<_>>()
        .join(", ")
}

/// Locals the call needs: allocated C strings, structs and trampolines.
fn render_param_bindings(out: &mut String, params: &[Param], prefix: &str, indent: &str) {
    for param in params {
        let name = param.name.to_lower_camel_case();
        match &param.ty {
            TypeRef::String | TypeRef::CString => {
                writeln!(
                    out,
                    "{indent}final {name}Native = {name}.toNativeUtf8().cast<ffi.Char>();"
                )
                .unwrap();
            }
            TypeRef::Struct { name: type_name, .. } => match host_type(type_name) {
                Some(host) => {
                    writeln!(
                        out,
                        "{indent}final {name}Pointer = pkg_ffi.calloc<{C}.{}>();",
                        c_type_name(prefix, type_name)
                    )
                    .unwrap();
                    for (field, getter) in host.fields {
                        writeln!(
                            out,
                            "{indent}{name}Pointer.ref.{field} = {};",
                            fill(getter, &name)
                        )
                        .unwrap();
                    }
                }
                None => {
                    writeln!(out, "{indent}final {name}Pointer = {name}.allocNative();").unwrap();
                }
            },
            TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
                writeln!(
                    out,
                    "{indent}final {name}Items = pkg_ffi.calloc<ffi.Pointer<ffi.Char>>({name}.length);"
                )
                .unwrap();
                writeln!(out, "{indent}for (var i = 0; i < {name}.length; i++) {{").unwrap();
                writeln!(
                    out,
                    "{indent}  {name}Items[i] = {name}[i].toNativeUtf8().cast<ffi.Char>();"
                )
                .unwrap();
                writeln!(out, "{indent}}}").unwrap();
                writeln!(
                    out,
                    "{indent}final {name}List = pkg_ffi.calloc<{C}.native_string_list_t>();"
                )
                .unwrap();
                writeln!(out, "{indent}{name}List.ref.items = {name}Items;").unwrap();
                writeln!(out, "{indent}{name}List.ref.count = {name}.length;").unwrap();
            }
            TypeRef::Map { .. } => {
                writeln!(
                    out,
                    "{indent}final {name}Keys = pkg_ffi.calloc<ffi.Pointer<ffi.Char>>({name}.length);"
                )
                .unwrap();
                writeln!(
                    out,
                    "{indent}final {name}Values = pkg_ffi.calloc<ffi.Pointer<ffi.Char>>({name}.length);"
                )
                .unwrap();
                writeln!(out, "{indent}var {name}Index = 0;").unwrap();
                writeln!(out, "{indent}{name}.forEach((key, value) {{").unwrap();
                writeln!(
                    out,
                    "{indent}  {name}Keys[{name}Index] = key.toNativeUtf8().cast<ffi.Char>();"
                )
                .unwrap();
                writeln!(
                    out,
                    "{indent}  {name}Values[{name}Index] = value.toNativeUtf8().cast<ffi.Char>();"
                )
                .unwrap();
                writeln!(out, "{indent}  {name}Index++;").unwrap();
                writeln!(out, "{indent}}});").unwrap();
                writeln!(
                    out,
                    "{indent}final {name}Map = pkg_ffi.calloc<{C}.native_string_map_t>();"
                )
                .unwrap();
                writeln!(out, "{indent}{name}Map.ref.keys = {name}Keys;").unwrap();
                writeln!(out, "{indent}{name}Map.ref.values = {name}Values;").unwrap();
                writeln!(out, "{indent}{name}Map.ref.count = {name}.length;").unwrap();
            }
            TypeRef::Callback { params: args } => {
                render_callback_binding(out, &name, args, indent, false);
            }
            TypeRef::Optional { inner } => match inner.as_ref() {
                TypeRef::String | TypeRef::CString => {
                    writeln!(
                        out,
                        "{indent}final {name}Native = {name} == null\n{indent}    ? ffi.nullptr\n{indent}    : {name}.toNativeUtf8().cast<ffi.Char>();"
                    )
                    .unwrap();
                }
                TypeRef::Struct { name: type_name, .. } => match host_type(type_name) {
                    Some(host) => {
                        writeln!(
                            out,
                            "{indent}final {name}Pointer = {name} == null\n{indent}    ? ffi.nullptr\n{indent}    : pkg_ffi.calloc<{C}.{}>();",
                            c_type_name(prefix, type_name)
                        )
                        .unwrap();
                        writeln!(out, "{indent}if ({name} != null) {{").unwrap();
                        for (field, getter) in host.fields {
                            writeln!(
                                out,
                                "{indent}  {name}Pointer.ref.{field} = {};",
                                fill(getter, &name)
                            )
                            .unwrap();
                        }
                        writeln!(out, "{indent}}}").unwrap();
                    }
                    None => {
                        writeln!(
                            out,
                            "{indent}final {name}Pointer = {name}?.allocNative() ?? ffi.nullptr;"
                        )
                        .unwrap();
                    }
                },
                TypeRef::Callback { params: args } => {
                    render_callback_binding(out, &name, args, indent, true);
                }
                _ => {}
            },
            _ => {}
        }
    }
}

fn render_callback_binding(
    out: &mut String,
    name: &str,
    params: &[TypeRef],
    indent: &str,
    optional: bool,
) {
    let c_args: Vec<String> = params
        .iter()
        .map(dart_native_type)
        .chain(std::iter::once("ffi.Pointer<ffi.Void>".to_string()))
        .collect();
    let dart_args: Vec<String> = params
        .iter()
        .enumerate()
        .map(|(index, ty)| format!("{} arg{index}", dart_field_type(ty)))
        .chain(std::iter::once("ffi.Pointer<ffi.Void> _".to_string()))
        .collect();
    let forwarded: Vec<String> = (0..params.len()).map(|i| format!("arg{i}")).collect();

    let guard = if optional {
        format!("{name} == null ? null : ")
    } else {
        String::new()
    };
    writeln!(
        out,
        "{indent}final {name}Callable = {guard}ffi.NativeCallable<\n{indent}    ffi.Void Function({})>.isolateLocal(",
        c_args.join(", ")
    )
    .unwrap();
    writeln!(out, "{indent}  ({}) {{", dart_args.join(", ")).unwrap();
    writeln!(out, "{indent}    {name}({});", forwarded.join(", ")).unwrap();
    writeln!(out, "{indent}  }},").unwrap();
    writeln!(out, "{indent});").unwrap();
    if optional {
        writeln!(
            out,
            "{indent}if ({name}Callable != null) _listeners.add({name}Callable);"
        )
        .unwrap();
    } else {
        writeln!(out, "{indent}_listeners.add({name}Callable);").unwrap();
    }
}

/// Frees whatever `render_param_bindings` allocated, after the call.
fn render_param_cleanup(out: &mut String, params: &[Param], indent: &str) {
    for param in params {
        let name = param.name.to_lower_camel_case();
        match &param.ty {
            TypeRef::String | TypeRef::CString => {
                writeln!(out, "{indent}pkg_ffi.calloc.free({name}Native);").unwrap();
            }
            TypeRef::Struct { name: type_name, .. } => {
                if host_type(type_name).is_some() {
                    writeln!(out, "{indent}pkg_ffi.calloc.free({name}Pointer);").unwrap();
                } else {
                    writeln!(out, "{indent}{type_name}.freeNative({name}Pointer);").unwrap();
                }
            }
            TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
                writeln!(out, "{indent}for (var i = 0; i < {name}.length; i++) {{").unwrap();
                writeln!(out, "{indent}  pkg_ffi.calloc.free({name}Items[i]);").unwrap();
                writeln!(out, "{indent}}}").unwrap();
                writeln!(out, "{indent}pkg_ffi.calloc.free({name}Items);").unwrap();
                writeln!(out, "{indent}pkg_ffi.calloc.free({name}List);").unwrap();
            }
            TypeRef::Map { .. } => {
                writeln!(out, "{indent}for (var i = 0; i < {name}.length; i++) {{").unwrap();
                writeln!(out, "{indent}  pkg_ffi.calloc.free({name}Keys[i]);").unwrap();
                writeln!(out, "{indent}  pkg_ffi.calloc.free({name}Values[i]);").unwrap();
                writeln!(out, "{indent}}}").unwrap();
                writeln!(out, "{indent}pkg_ffi.calloc.free({name}Keys);").unwrap();
                writeln!(out, "{indent}pkg_ffi.calloc.free({name}Values);").unwrap();
                writeln!(out, "{indent}pkg_ffi.calloc.free({name}Map);").unwrap();
            }
            TypeRef::Optional { inner } => match inner.as_ref() {
                TypeRef::String | TypeRef::CString => {
                    writeln!(
                        out,
                        "{indent}if ({name}Native != ffi.nullptr) pkg_ffi.calloc.free({name}Native);"
                    )
                    .unwrap();
                }
                TypeRef::Struct { name: type_name, .. } => {
                    let free = if host_type(type_name).is_some() {
                        format!("pkg_ffi.calloc.free({name}Pointer)")
                    } else {
                        format!("{type_name}.freeNative({name}Pointer.cast())")
                    };
                    writeln!(
                        out,
                        "{indent}if ({name}Pointer != ffi.nullptr) {{\n{indent}  {free};\n{indent}}}"
                    )
                    .unwrap();
                }
                _ => {}
            },
            _ => {}
        }
    }
}

fn call_args(params: &[Param], receiver: Option<String>) -> String {
    let mut args: Vec<String> = receiver.into_iter().collect();
    for param in params {
        let name = param.name.to_lower_camel_case();
        match &param.ty {
            TypeRef::String | TypeRef::CString => args.push(format!("{name}Native")),
            TypeRef::Object { shared: true, .. } => {
                args.push(format!("{name}?.nativeHandle ?? 0"))
            }
            TypeRef::Object { .. } => args.push(format!("{name}.nativeHandle")),
            TypeRef::Struct { .. } => args.push(format!("{name}Pointer.ref")),
            TypeRef::Enum { .. } => args.push(format!("{name}.raw")),
            TypeRef::Vector { .. } => args.push(format!("{name}List.ref")),
            TypeRef::Map { .. } => args.push(format!("{name}Map.ref")),
            TypeRef::Callback { .. } => {
                args.push(format!("{name}Callable.nativeFunction"));
                args.push("ffi.nullptr".to_string());
            }
            TypeRef::Optional { inner } => match inner.as_ref() {
                TypeRef::String | TypeRef::CString => args.push(format!("{name}Native")),
                TypeRef::Object { .. } => args.push(format!("{name}?.nativeHandle ?? 0")),
                TypeRef::Struct { .. } => args.push(format!("{name}Pointer.cast()")),
                TypeRef::Callback { .. } => {
                    args.push(format!(
                        "{name}Callable?.nativeFunction ?? ffi.nullptr"
                    ));
                    args.push("ffi.nullptr".to_string());
                }
                _ => args.push(name),
            },
            _ => args.push(name),
        }
    }
    args.join(", ")
}

fn render_return(
    out: &mut String,
    ty: &TypeRef,
    call: &str,
    params: &[Param],
    header: &Header,
    prefix: &str,
) {
    let needs_cleanup = params.iter().any(|param| {
        matches!(
            param.ty.unwrap_optional(),
            TypeRef::String | TypeRef::CString | TypeRef::Struct { .. } | TypeRef::Vector { .. } | TypeRef::Map { .. }
        )
    });

    match ty {
        TypeRef::Void => {
            writeln!(out, "    {call};").unwrap();
            if needs_cleanup {
                render_param_cleanup(out, params, "    ");
            }
        }
        TypeRef::String | TypeRef::CString => {
            writeln!(out, "    final resultPointer = {call};").unwrap();
            if needs_cleanup {
                render_param_cleanup(out, params, "    ");
            }
            writeln!(out, "    if (resultPointer == ffi.nullptr) return null;").unwrap();
            writeln!(
                out,
                "    final result = resultPointer.cast<pkg_ffi.Utf8>().toDartString();"
            )
            .unwrap();
            writeln!(out, "    _bindings.{STRING_FREE_FN}(resultPointer);").unwrap();
            writeln!(out, "    return result;").unwrap();
        }
        TypeRef::Struct { name, .. } => {
            writeln!(out, "    final raw = {call};").unwrap();
            if needs_cleanup {
                render_param_cleanup(out, params, "    ");
            }
            if let Some(host) = host_type(name) {
                writeln!(out, "    return {};", fill(host.from_raw, "raw")).unwrap();
                return;
            }
            let owns = header
                .structs
                .iter()
                .any(|item| item.name == *name && struct_has_owned_fields(item));
            if owns {
                writeln!(out, "    final result = {name}.fromNative(raw);").unwrap();
                writeln!(
                    out,
                    "    final rawPointer = pkg_ffi.calloc<{C}.{}>();",
                    c_type_name(prefix, name)
                )
                .unwrap();
                writeln!(out, "    rawPointer.ref = raw;").unwrap();
                writeln!(
                    out,
                    "    _bindings.{}(rawPointer);",
                    c_free_symbol(prefix, name)
                )
                .unwrap();
                writeln!(out, "    pkg_ffi.calloc.free(rawPointer);").unwrap();
                writeln!(out, "    return result;").unwrap();
            } else {
                writeln!(out, "    return {name}.fromNative(raw);").unwrap();
            }
        }
        TypeRef::Enum { name, .. } => {
            writeln!(out, "    final raw = {call};").unwrap();
            if needs_cleanup {
                render_param_cleanup(out, params, "    ");
            }
            writeln!(out, "    return {name}.fromValue(raw.value);").unwrap();
        }
        TypeRef::Object { name, .. } => {
            writeln!(out, "    final handle = {call};").unwrap();
            if needs_cleanup {
                render_param_cleanup(out, params, "    ");
            }
            writeln!(out, "    if (handle == 0) return null;").unwrap();
            writeln!(out, "    return {name}.fromHandle(handle);").unwrap();
        }
        TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
            writeln!(out, "    final list = {call};").unwrap();
            if needs_cleanup {
                render_param_cleanup(out, params, "    ");
            }
            writeln!(out, "    final items = <String>[];").unwrap();
            writeln!(out, "    for (var i = 0; i < list.count; i++) {{").unwrap();
            writeln!(out, "      final item = list.items[i];").unwrap();
            writeln!(out, "      if (item == ffi.nullptr) continue;").unwrap();
            writeln!(
                out,
                "      items.add(item.cast<pkg_ffi.Utf8>().toDartString());"
            )
            .unwrap();
            writeln!(out, "    }}").unwrap();
            writeln!(
                out,
                "    final listPointer = pkg_ffi.calloc<{C}.native_string_list_t>();"
            )
            .unwrap();
            writeln!(out, "    listPointer.ref = list;").unwrap();
            writeln!(out, "    _bindings.{STRING_LIST_FREE_FN}(listPointer);").unwrap();
            writeln!(out, "    pkg_ffi.calloc.free(listPointer);").unwrap();
            writeln!(out, "    return items;").unwrap();
        }
        TypeRef::Vector { element } => {
            let TypeRef::Object { name, .. } = element.as_ref() else {
                writeln!(out, "    return {call};").unwrap();
                return;
            };
            let field = c_list_field(name);
            writeln!(out, "    final list = {call};").unwrap();
            if needs_cleanup {
                render_param_cleanup(out, params, "    ");
            }
            writeln!(out, "    final items = <{name}>[];").unwrap();
            writeln!(out, "    for (var i = 0; i < list.count; i++) {{").unwrap();
            writeln!(
                out,
                "      items.add({name}.fromHandle(list.{field}[i]));"
            )
            .unwrap();
            writeln!(out, "    }}").unwrap();
            writeln!(
                out,
                "    final listPointer = pkg_ffi.calloc<{C}.{}>();",
                codegen_shared::naming::c_list_type_name(prefix, name)
            )
            .unwrap();
            writeln!(out, "    listPointer.ref = list;").unwrap();
            writeln!(
                out,
                "    // The handles now belong to `items`; free just the array."
            )
            .unwrap();
            writeln!(
                out,
                "    _bindings.{}(listPointer);",
                c_list_release_symbol(prefix, name)
            )
            .unwrap();
            writeln!(out, "    pkg_ffi.calloc.free(listPointer);").unwrap();
            writeln!(out, "    return items;").unwrap();
        }
        TypeRef::Map { .. } => {
            writeln!(out, "    final raw = {call};").unwrap();
            if needs_cleanup {
                render_param_cleanup(out, params, "    ");
            }
            writeln!(out, "    final entries = <String, String>{{}};").unwrap();
            writeln!(out, "    for (var i = 0; i < raw.count; i++) {{").unwrap();
            writeln!(out, "      final key = raw.keys[i];").unwrap();
            writeln!(out, "      if (key == ffi.nullptr) continue;").unwrap();
            writeln!(out, "      final value = raw.values[i];").unwrap();
            writeln!(
                out,
                "      entries[key.cast<pkg_ffi.Utf8>().toDartString()] = value == ffi.nullptr\n          ? ''\n          : value.cast<pkg_ffi.Utf8>().toDartString();"
            )
            .unwrap();
            writeln!(out, "    }}").unwrap();
            writeln!(
                out,
                "    final rawPointer = pkg_ffi.calloc<{C}.native_string_map_t>();"
            )
            .unwrap();
            writeln!(out, "    rawPointer.ref = raw;").unwrap();
            writeln!(out, "    _bindings.{STRING_MAP_FREE_FN}(rawPointer);").unwrap();
            writeln!(out, "    pkg_ffi.calloc.free(rawPointer);").unwrap();
            writeln!(out, "    return entries;").unwrap();
        }
        TypeRef::Optional { inner } => render_return(out, inner, call, params, header, prefix),
        _ => {
            if needs_cleanup {
                writeln!(out, "    final result = {call};").unwrap();
                render_param_cleanup(out, params, "    ");
                writeln!(out, "    return result;").unwrap();
            } else {
                writeln!(out, "    return {call};").unwrap();
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

fn dart_return_type(ty: &TypeRef) -> String {
    match ty {
        TypeRef::Void => "void".to_string(),
        other => dart_field_type(other),
    }
}

fn dart_field_type(ty: &TypeRef) -> String {
    match ty {
        TypeRef::Void => "void".to_string(),
        TypeRef::Bool => "bool".to_string(),
        TypeRef::Int { .. } => "int".to_string(),
        TypeRef::Float { .. } => "double".to_string(),
        TypeRef::String | TypeRef::CString => "String?".to_string(),
        TypeRef::Alias { name, .. } => name.clone(),
        TypeRef::Enum { name, .. } => name.clone(),
        TypeRef::Struct { name, .. } => match host_type(name) {
            Some(host) => host.dart.to_string(),
            None => name.clone(),
        },
        TypeRef::Object { name, .. } => format!("{name}?"),
        TypeRef::Vector { element } => format!("List<{}>", dart_element_type(element)),
        TypeRef::Map { .. } => "Map<String, String>".to_string(),
        TypeRef::Optional { inner } => {
            let base = dart_field_type(inner);
            if base.ends_with('?') {
                base
            } else {
                format!("{base}?")
            }
        }
        TypeRef::RawPointer => "ffi.Pointer<ffi.Void>".to_string(),
        TypeRef::Callback { params } => format!("void Function({})?", dart_callback_args(params)),
        TypeRef::Unsupported { .. } => "Object?".to_string(),
    }
}

fn dart_element_type(ty: &TypeRef) -> String {
    match ty {
        TypeRef::Object { name, .. } => name.clone(),
        TypeRef::String | TypeRef::CString => "String".to_string(),
        other => dart_field_type(other),
    }
}

/// How a callback argument arrives across `dart:ffi`.
fn dart_native_type(ty: &TypeRef) -> String {
    match ty {
        TypeRef::Bool => "ffi.Bool".to_string(),
        TypeRef::Float { name } if name == "float" => "ffi.Float".to_string(),
        TypeRef::Float { .. } => "ffi.Double".to_string(),
        TypeRef::Alias { underlying, .. } => dart_native_type(underlying),
        TypeRef::Int { name } => match name.as_str() {
            "char" | "signed char" => "ffi.Char",
            "short" => "ffi.Short",
            "long" => "ffi.Long",
            "long long" => "ffi.LongLong",
            "unsigned char" => "ffi.UnsignedChar",
            "unsigned short" => "ffi.UnsignedShort",
            "unsigned int" => "ffi.UnsignedInt",
            "unsigned long" => "ffi.UnsignedLong",
            "unsigned long long" => "ffi.UnsignedLongLong",
            _ => "ffi.Int",
        }
        .to_string(),
        _ => "ffi.Pointer<ffi.Void>".to_string(),
    }
}

/// Reads one value out of its C form.
fn dart_from_native(ty: &TypeRef, access: &str) -> String {
    match ty {
        TypeRef::String | TypeRef::CString => format!(
            "{access} == ffi.nullptr ? null : {access}.cast<pkg_ffi.Utf8>().toDartString()"
        ),
        // Copied out: the C side frees the list when the callback returns.
        TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => format!(
            "[for (var i = 0; i < {access}.count; i++) if ({access}.items[i] != ffi.nullptr) {access}.items[i].cast<pkg_ffi.Utf8>().toDartString()]"
        ),
        // In a struct, ffigen types a C enum as a plain int; only parameters and
        // returns get the generated Dart enum.
        TypeRef::Enum { name, .. } => format!("{name}.fromValue({access})"),
        TypeRef::Struct { name, .. } => match host_type(name) {
            Some(host) => fill(host.from_raw, access),
            None => format!("{name}.fromNative({access})"),
        },
        // Borrowed for the callback's duration only, so it must not be attached
        // to the finalizer that would release it.
        TypeRef::Object { name, .. } => format!("{name}.borrowed({access})"),
        _ => access.to_string(),
    }
}

fn dart_enum_case(name: &str) -> String {
    name.strip_prefix('k').unwrap_or(name).to_lower_camel_case()
}

fn is_callback(ty: &TypeRef) -> bool {
    codegen_shared::naming::is_callback(ty)
}
