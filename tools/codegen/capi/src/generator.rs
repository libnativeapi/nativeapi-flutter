use std::collections::BTreeSet;
use std::fmt::Write;
use std::path::Path;

use heck::ToSnakeCase;

use codegen_shared::naming::{
    c_to_cpp_fn, cpp_to_c_fn,
    c_add_listener_symbol, c_call_args, c_callback_type_name, c_constructor_symbol, c_enum_variant,
    c_event_callback_type, c_event_type_enum, c_event_variant, c_event_variant_field, c_field_type,
    c_free_symbol, c_invalid_handle_macro, c_list_field, c_list_free_symbol, c_list_release_symbol,
    c_list_type_name, c_method_symbol, c_native_object_symbol, c_param_list, c_param_type,
    c_params, c_remove_listener_symbol, c_return_type, c_self_param, c_type_name, cpp_argument_expr,
    cpp_event_converter, cpp_event_releaser, foreign_types, header_dependencies, is_callback,
    listed_classes, relative_include, struct_has_owned_fields, TypeOrigins, COMMON_HEADER,
    LISTENER_ID_TYPE, STRING_DUP_FN, STRING_FREE_FN, STRING_LIST_DUP_FN, STRING_LIST_FREE_FN,
    STRING_LIST_TYPE,
    STRING_MAP_DUP_FN, STRING_MAP_TYPE, c_release_user_data_param, RELEASE_USER_DATA_TYPE,
    USER_DATA_HEADER,
};
use codegen_shared::GeneratedFile;
use codegen_shared::ir::{
    Api, Class, Constructor, Enum, EventGroup, Field, Header, Method, Param, Struct, TypeRef,
};

pub fn generate(
    api: &Api,
    header: &Header,
    origins: &TypeOrigins,
    capi_out: &Path,
    prefix: &str,
) -> Vec<GeneratedFile> {
    let h_name = format!("{}_c.h", header.stem);
    let cpp_name = format!("{}_c.cpp", header.stem);

    let listed = listed_classes(api);

    vec![
        GeneratedFile {
            path: capi_out.join(&h_name),
            contents: render_c_header(api, header, origins, &listed, capi_out, prefix),
        },
        GeneratedFile {
            path: capi_out.join(&cpp_name),
            contents: render_c_source(api, header, origins, &listed, capi_out, prefix, &h_name),
        },
    ]
}

/// The one header every generated header includes: the handful of definitions
/// that have no natural owner among the C++ headers.
pub fn generate_common(capi_out: &Path, prefix: &str) -> GeneratedFile {
    let mut out = String::new();
    write_banner(&mut out);
    writeln!(out, "#pragma once").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "#include <stdbool.h>").unwrap();
    writeln!(out, "#include <stdint.h>").unwrap();
    writeln!(out).unwrap();
    write_export_macro(&mut out);
    writeln!(out, "#ifdef __cplusplus").unwrap();
    writeln!(out, "extern \"C\" {{").unwrap();
    writeln!(out, "#endif").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "/// Identifies one registered event listener.").unwrap();
    writeln!(out, "typedef uint64_t {LISTENER_ID_TYPE};").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "/// Returned by add_listener when registration failed.").unwrap();
    writeln!(
        out,
        "#define {}INVALID_LISTENER_ID (({LISTENER_ID_TYPE})0)",
        prefix.to_uppercase()
    )
    .unwrap();
    writeln!(out).unwrap();
    for line in [
        "/// Takes back the `user_data` passed with a callback.",
        "///",
        "/// Every function taking a callback also takes one of these (may be NULL).",
        "/// The core calls it exactly once per call — including when the call fails",
        "/// or the callback is NULL — after the last time it can call that callback:",
        "/// when a listener is removed, a callback replaced, a registration ended, or",
        "/// its owner destroyed. It runs on the main thread, never inside the call",
        "/// that let the callback go.",
    ] {
        writeln!(out, "{line}").unwrap();
    }
    writeln!(out, "typedef void (*{RELEASE_USER_DATA_TYPE})(void* user_data);").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "#ifdef __cplusplus").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out, "#endif").unwrap();

    GeneratedFile {
        path: capi_out.join(COMMON_HEADER),
        contents: out,
    }
}

/// The public umbrella header: every C++ header in the generation set plus
/// every C header generated from it. Hand-maintaining this drifted every time a
/// module was added, which is exactly the sort of bookkeeping the generator
/// already has the information to do.
pub fn generate_umbrella(api: &Api, include_out: &Path, capi_dir: &Path) -> GeneratedFile {
    let mut out = String::new();
    write_banner(&mut out);
    writeln!(out, "#pragma once").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "#ifdef __cplusplus").unwrap();
    writeln!(out, "// C++ API").unwrap();
    let mut cpp: Vec<String> = api
        .headers
        .iter()
        .map(|header| relative_include(include_out, &header.path))
        .collect();
    cpp.sort();
    for include in cpp {
        writeln!(out, "#include \"{include}\"").unwrap();
    }
    writeln!(out, "#endif").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "// C API (usable from both C and C++)").unwrap();
    let capi_prefix = relative_include(include_out, capi_dir);
    let mut c: Vec<String> = api
        .headers
        .iter()
        .map(|header| format!("{capi_prefix}/{}_c.h", header.stem))
        .collect();
    c.push(format!("{capi_prefix}/{COMMON_HEADER}"));
    c.push(format!(
        "{capi_prefix}/{}",
        codegen_shared::naming::STRING_UTILS_HEADER
    ));
    c.sort();
    for include in c {
        writeln!(out, "#include \"{include}\"").unwrap();
    }

    GeneratedFile {
        path: include_out.join("nativeapi.h"),
        contents: out,
    }
}

/// Structs and enums this header uses that are declared elsewhere. Their
/// C++ <-> C converters are emitted into this translation unit as well, since
/// converters are file-local by design.
fn imported_types<'a>(
    api: &'a Api,
    header: &Header,
    origins: &TypeOrigins,
) -> (Vec<&'a Enum>, Vec<&'a Struct>, Vec<&'a Header>) {
    // Converters are file-local, so pulling in a struct also means pulling in
    // the converters its own fields need — transitively.
    let mut names: BTreeSet<String> = foreign_types(header, origins).into_iter().collect();
    loop {
        let mut added = false;
        for other in &api.headers {
            for item in &other.structs {
                if !names.contains(&item.name) {
                    continue;
                }
                for field in &item.fields {
                    for referenced in field.ty.named_types() {
                        if referenced != header.stem && names.insert(referenced.to_string()) {
                            added = true;
                        }
                    }
                }
            }
        }
        if !added {
            break;
        }
    }

    let mut enums = Vec::new();
    let mut structs = Vec::new();
    let mut headers: Vec<&Header> = Vec::new();

    for other in &api.headers {
        if other.stem == header.stem {
            continue;
        }
        let mut used = false;
        for item in &other.enums {
            if names.contains(&item.name) {
                enums.push(item);
                used = true;
            }
        }
        for item in &other.structs {
            if names.contains(&item.name) {
                structs.push(item);
                used = true;
            }
        }
        for item in &other.classes {
            if names.contains(&item.name) {
                used = true;
            }
        }
        for group in &other.events {
            if names.contains(&group.name) {
                used = true;
            }
        }
        if used {
            headers.push(other);
        }
    }
    (enums, structs, headers)
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

fn render_c_header(
    api: &Api,
    header: &Header,
    origins: &TypeOrigins,
    listed: &BTreeSet<String>,
    capi_out: &Path,
    prefix: &str,
) -> String {
    let mut out = String::new();
    write_banner(&mut out);
    writeln!(out, "#pragma once").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "#include <stdbool.h>").unwrap();
    writeln!(out, "#include <stdint.h>").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "#include \"{COMMON_HEADER}\"").unwrap();
    if header_uses_string_containers(header) {
writeln!(
            out,
            "#include \"{}\"",
            codegen_shared::naming::STRING_UTILS_HEADER
        )
        .unwrap();
    }
    for dep in header_dependencies(header, origins) {
        writeln!(out, "#include \"{dep}_c.h\"").unwrap();
    }
    writeln!(out).unwrap();

    write_export_macro(&mut out);
    writeln!(out, "#ifdef __cplusplus").unwrap();
    writeln!(out, "extern \"C\" {{").unwrap();
    writeln!(out, "#endif").unwrap();
    writeln!(out).unwrap();

    for alias in &header.aliases {
        // Only the owning header declares it; the rest include that header, so
        // the typedef is never defined twice in one translation unit.
        if origins.get(&alias.name).map(String::as_str) != Some(header.stem.as_str()) {
            continue;
        }
        writeln!(
            out,
            "typedef {} {};",
            c_field_type(&alias.underlying, prefix),
            c_type_name(prefix, &alias.name)
        )
        .unwrap();
        writeln!(out).unwrap();
    }

    for item in &header.enums {
        render_c_enum(&mut out, item, prefix);
    }

    // Function-pointer typedefs come before anything that names them.
    for callback in collect_callbacks(header, prefix) {
        render_callback_typedef(&mut out, &callback, prefix);
    }

    for item in &header.structs {
        render_c_struct(&mut out, item, prefix);
    }

    // Opaque handle for every instance class; list types only where some API
    // actually returns a vector of them.
    for class in header.classes.iter().filter(|class| class.is_instance()) {
        render_c_handle_types(&mut out, class, listed.contains(&class.name), prefix);
    }

    for group in &header.events {
        render_c_event_types(&mut out, group, prefix);
    }

    for item in &header.structs {
        render_struct_api_decl(&mut out, item, prefix);
    }

    for class in &header.classes {
        for ctor in &class.constructors {
            writeln!(
                out,
                "/// Creates a {} instance; release it with {}().",
                class.name,
                c_free_symbol(prefix, &class.name)
            )
            .unwrap();
            writeln!(out, "FFI_PLUGIN_EXPORT").unwrap();
            writeln!(
                out,
                "{} {}({});",
                c_type_name(prefix, &class.name),
                c_constructor_symbol(prefix, class, ctor),
                c_ctor_params(class, ctor, prefix)
            )
            .unwrap();
            writeln!(out).unwrap();
        }

        for method in &class.methods {
            write_ownership_note(&mut out, &method.return_type, prefix);
            writeln!(out, "FFI_PLUGIN_EXPORT").unwrap();
            writeln!(
                out,
                "{} {}({});",
                c_return_type(&method.return_type, prefix),
                c_method_symbol(prefix, class, method),
                c_params(method, Some(class), prefix)
            )
            .unwrap();
            writeln!(out).unwrap();
        }

        if class.is_instance() {
            render_c_handle_functions_decl(&mut out, class, listed.contains(&class.name), prefix);
        }
        render_listener_decl(&mut out, api, class, prefix);
    }

    writeln!(out, "#ifdef __cplusplus").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out, "#endif").unwrap();

    render_cpp_bridge_decl(&mut out, header, prefix);
    render_cpp_converters(&mut out, header, capi_out, prefix);
    out
}

/// The C++ <-> C converters for the types this header declares, defined inline
/// in the header that owns them.
///
/// They cannot be emitted per `.cpp`: the macOS/iOS SwiftPM plugin `#include`s
/// every generated `*_c.cpp` into one translation unit, where copies of the
/// same helper are a redefinition (`inline` allows one definition per TU, not
/// several within one). Living in the owning header gives every consumer the
/// single definition through the include it already has.
fn render_cpp_converters(out: &mut String, header: &Header, capi_out: &Path, prefix: &str) {
    if header.enums.is_empty() && header.structs.is_empty() {
        return;
    }

    writeln!(out).unwrap();
    writeln!(out, "#ifdef __cplusplus").unwrap();
    // The C++ original of these types, plus the string/container primitives the
    // converters hand their owned members to.
    writeln!(
        out,
        "#include \"{}\"",
        relative_include(capi_out, &header.path)
    )
    .unwrap();
    writeln!(
        out,
        "#include \"{}\"",
        codegen_shared::naming::STRING_UTILS_HEADER
    )
    .unwrap();
    writeln!(out, "#include \"{USER_DATA_HEADER}\"").unwrap();
    writeln!(out).unwrap();
    writeln!(
        out,
        "// Conversion helpers between these C types and their C++ originals."
    )
    .unwrap();
    writeln!(out).unwrap();

    // Declared up front so a converter can call one defined further down.
    for item in &header.enums {
        writeln!(
            out,
            "inline {} {}({} value);",
            c_type_name(prefix, &item.name),
            cpp_to_c_fn(&item.name),
            item.qualified_name
        )
        .unwrap();
        writeln!(
            out,
            "inline {} {}({} value);",
            item.qualified_name,
            c_to_cpp_fn(&item.name),
            c_type_name(prefix, &item.name)
        )
        .unwrap();
    }
    for item in &header.structs {
        writeln!(
            out,
            "inline {} {}(const {}& value);",
            c_type_name(prefix, &item.name),
            cpp_to_c_fn(&item.name),
            item.qualified_name
        )
        .unwrap();
        writeln!(
            out,
            "inline {} {}(const {}& value);",
            item.qualified_name,
            c_to_cpp_fn(&item.name),
            c_type_name(prefix, &item.name)
        )
        .unwrap();
    }
    writeln!(out).unwrap();

    for item in &header.enums {
        render_c_enum_converter(out, item, prefix);
        render_cpp_enum_converter(out, item, prefix);
    }
    for item in &header.structs {
        render_c_struct_converter(out, item, prefix);
        render_cpp_struct_converter(out, item, prefix);
    }

    writeln!(out, "#endif  // __cplusplus").unwrap();
}

fn write_export_macro(out: &mut String) {
    writeln!(out, "#if _WIN32").unwrap();
    writeln!(out, "#define FFI_PLUGIN_EXPORT __declspec(dllexport)").unwrap();
    writeln!(out, "#else").unwrap();
    writeln!(out, "#define FFI_PLUGIN_EXPORT").unwrap();
    writeln!(out, "#endif").unwrap();
    writeln!(out).unwrap();
}

fn write_ownership_note(out: &mut String, ty: &TypeRef, prefix: &str) {
    match ty.unwrap_optional() {
        TypeRef::String => writeln!(
            out,
            "/// Caller owns the returned string; free it with {STRING_FREE_FN}()."
        )
        .unwrap(),
        TypeRef::Object { name, .. } => writeln!(
            out,
            "/// Caller owns the returned handle; release it with {}().",
            c_free_symbol(prefix, name)
        )
        .unwrap(),
        _ => {}
    }
}

/// `typedef uint64_t native_window_t;` plus the sentinel that stands in for
/// "no window" — handles are table indices, so NULL has no meaning here.
fn render_c_handle_types(out: &mut String, class: &Class, listed: bool, prefix: &str) {
    let handle = c_type_name(prefix, &class.name);
    writeln!(out, "/// Opaque {} handle.", class.name).unwrap();
    writeln!(out, "///").unwrap();
    writeln!(
        out,
        "/// A generational index into the library's handle table, NOT a pointer:"
    )
    .unwrap();
    writeln!(
        out,
        "/// never dereference it, and compare it against {} rather than NULL.",
        c_invalid_handle_macro(prefix, &class.name)
    )
    .unwrap();
    writeln!(
        out,
        "/// Releasing a handle invalidates it; later calls fail safely instead of"
    )
    .unwrap();
    writeln!(out, "/// touching freed memory.").unwrap();
    writeln!(out, "typedef uint64_t {handle};").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "/// Never refers to a live {}.", class.name).unwrap();
    writeln!(
        out,
        "#define {} (({handle})0)",
        c_invalid_handle_macro(prefix, &class.name)
    )
    .unwrap();
    writeln!(out).unwrap();
    if !listed {
        return;
    }
    writeln!(out, "/// Owning list of {} handles.", class.name).unwrap();
    writeln!(out, "typedef struct {{").unwrap();
    writeln!(out, "  {handle}* {};", c_list_field(&class.name)).unwrap();
    writeln!(out, "  long count;").unwrap();
    writeln!(out, "}} {};", c_list_type_name(prefix, &class.name)).unwrap();
    writeln!(out).unwrap();
}

fn render_c_handle_functions_decl(out: &mut String, class: &Class, listed: bool, prefix: &str) {
    let handle = c_type_name(prefix, &class.name);
    let self_param = c_self_param(class);
    let list_type = c_list_type_name(prefix, &class.name);

    if class.native_object {
        writeln!(
            out,
            "/// Platform-specific native object (NSScreen*, HMONITOR, ...)."
        )
        .unwrap();
        writeln!(out, "FFI_PLUGIN_EXPORT").unwrap();
        writeln!(
            out,
            "void* {}({handle} {self_param});",
            c_native_object_symbol(prefix, &class.name)
        )
        .unwrap();
        writeln!(out).unwrap();
    }

    writeln!(
        out,
        "/// Releases the caller's reference. Safe to call with an invalid or"
    )
    .unwrap();
    writeln!(out, "/// already-released handle.").unwrap();
    writeln!(out, "FFI_PLUGIN_EXPORT").unwrap();
    writeln!(
        out,
        "void {}({handle} {self_param});",
        c_free_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(out).unwrap();

    if !listed {
        return;
    }

    writeln!(out, "/// Frees the array and releases every handle it contains.").unwrap();
    writeln!(out, "FFI_PLUGIN_EXPORT").unwrap();
    writeln!(
        out,
        "void {}({list_type}* list);",
        c_list_free_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(out).unwrap();

    writeln!(
        out,
        "/// Frees only the array; the caller takes over the handles."
    )
    .unwrap();
    writeln!(out, "FFI_PLUGIN_EXPORT").unwrap();
    writeln!(
        out,
        "void {}({list_type}* list);",
        c_list_release_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(out).unwrap();
}

/// Listener registration for a class deriving from `EventEmitter<T>`.
fn render_listener_decl(out: &mut String, api: &Api, class: &Class, prefix: &str) {
    let Some(group) = emitted_group(api, class) else {
        return;
    };
    let callback = c_event_callback_type(prefix, &group.name);
    let receiver = listener_receiver_param(class, prefix);

    writeln!(
        out,
        "/// Registers @p callback for every {} this {} emits.",
        group.name, class.name
    )
    .unwrap();
    writeln!(
        out,
        "/// @return the listener id, or {}INVALID_LISTENER_ID on failure.",
        prefix.to_uppercase()
    )
    .unwrap();
    writeln!(out, "FFI_PLUGIN_EXPORT").unwrap();
    writeln!(
        out,
        "{LISTENER_ID_TYPE} {}({}{callback} callback, void* user_data, {RELEASE_USER_DATA_TYPE} release_user_data);",
        c_add_listener_symbol(prefix, &class.name),
        receiver
    )
    .unwrap();
    writeln!(out).unwrap();

    writeln!(out, "/// Unregisters a listener. Returns false if unknown.").unwrap();
    writeln!(out, "FFI_PLUGIN_EXPORT").unwrap();
    writeln!(
        out,
        "bool {}({}{LISTENER_ID_TYPE} listener_id);",
        c_remove_listener_symbol(prefix, &class.name),
        receiver
    )
    .unwrap();
    writeln!(out).unwrap();
}

/// `native_menu_t menu, ` for instance emitters, empty for singletons.
fn listener_receiver_param(class: &Class, prefix: &str) -> String {
    if class.is_instance() {
        format!(
            "{} {}, ",
            c_type_name(prefix, &class.name),
            c_self_param(class)
        )
    } else {
        String::new()
    }
}

fn emitted_group<'a>(api: &'a Api, class: &Class) -> Option<&'a EventGroup> {
    let event = class.event.as_ref()?;
    api.headers
        .iter()
        .flat_map(|header| header.events.iter())
        .find(|group| &group.name == event)
}

// ---------------------------------------------------------------------------
// Enums, structs, callbacks
// ---------------------------------------------------------------------------

fn render_c_enum(out: &mut String, item: &Enum, prefix: &str) {
    writeln!(out, "typedef enum {{").unwrap();
    for variant in &item.variants {
        writeln!(
            out,
            "  {} = {},",
            c_enum_variant(prefix, item, &variant.name),
            variant.value
        )
        .unwrap();
    }
    writeln!(out, "}} {};", c_type_name(prefix, &item.name)).unwrap();
    writeln!(out).unwrap();
}

fn render_c_struct(out: &mut String, item: &Struct, prefix: &str) {
    writeln!(out, "typedef struct {{").unwrap();
    for field in &item.fields {
        let name = field.name.to_snake_case();
        if is_callback(&field.ty) {
            writeln!(
                out,
                "  {} {name};",
                c_callback_type_name(prefix, &item.name, &field.name)
            )
            .unwrap();
            writeln!(
                out,
                "  void* {};",
                codegen_shared::naming::c_user_data_param(&field.name)
            )
            .unwrap();
            writeln!(
                out,
                "  {RELEASE_USER_DATA_TYPE} {};",
                c_release_user_data_param(&field.name)
            )
            .unwrap();
            continue;
        }
        writeln!(out, "  {} {name};", c_field_type(&field.ty, prefix)).unwrap();
    }
    writeln!(out, "}} {};", c_type_name(prefix, &item.name)).unwrap();
    writeln!(out).unwrap();
}

/// Free function declarations attached to a struct: static factories, const
/// accessors, exported constants, and the field releaser.
fn render_struct_api_decl(out: &mut String, item: &Struct, prefix: &str) {
    let c_name = c_type_name(prefix, &item.name);

    for constant in &item.constants {
        writeln!(out, "FFI_PLUGIN_EXPORT").unwrap();
        writeln!(
            out,
            "extern const {c_name} {};",
            c_struct_constant(prefix, &item.name, constant)
        )
        .unwrap();
        writeln!(out).unwrap();
    }

    for method in &item.methods {
        write_ownership_note(out, &method.return_type, prefix);
        writeln!(out, "FFI_PLUGIN_EXPORT").unwrap();
        writeln!(
            out,
            "{} {}({});",
            c_return_type(&method.return_type, prefix),
            c_struct_method_symbol(prefix, item, method),
            c_struct_method_params(item, method, prefix)
        )
        .unwrap();
        writeln!(out).unwrap();
    }

    if struct_has_owned_fields(item) {
        writeln!(out, "/// Frees everything the struct owns.").unwrap();
        writeln!(out, "FFI_PLUGIN_EXPORT").unwrap();
        writeln!(
            out,
            "void {}({c_name}* value);",
            c_free_symbol(prefix, &item.name)
        )
        .unwrap();
        writeln!(out).unwrap();
    }
}

fn c_struct_constant(prefix: &str, struct_name: &str, constant: &str) -> String {
    use heck::ToShoutySnakeCase;
    format!(
        "{}_{}_{}",
        prefix.trim_end_matches('_').to_shouty_snake_case(),
        struct_name.to_shouty_snake_case(),
        constant.to_shouty_snake_case()
    )
}

fn c_struct_method_symbol(prefix: &str, item: &Struct, method: &Method) -> String {
    format!(
        "{}{}_{}",
        prefix,
        item.name.to_snake_case(),
        method.name.to_snake_case()
    )
}

/// Struct methods take the value itself, not a handle: a struct is a value type
/// on both sides of the ABI.
fn c_struct_method_params(item: &Struct, method: &Method, prefix: &str) -> String {
    let mut params = Vec::new();
    if !method.is_static {
        params.push(format!(
            "{} {}",
            c_type_name(prefix, &item.name),
            item.name.to_snake_case()
        ));
    }
    params.extend(c_param_list(
        &method.params,
        prefix,
        &item.name,
        &method.name,
    ));
    if params.is_empty() {
        return "void".to_string();
    }
    params.join(", ")
}

/// Every callback typedef this header needs, in declaration order.
struct CallbackDecl {
    name: String,
    params: Vec<TypeRef>,
}

fn collect_callbacks(header: &Header, prefix: &str) -> Vec<CallbackDecl> {
    let mut seen = BTreeSet::new();
    let mut out = Vec::new();
    let mut push = |owner: &str, member: &str, ty: &TypeRef, out: &mut Vec<CallbackDecl>| {
        let TypeRef::Callback { params } = ty.unwrap_optional() else {
            return;
        };
        let name = c_callback_type_name(prefix, owner, member);
        if seen.insert(name.clone()) {
            out.push(CallbackDecl {
                name,
                params: params.clone(),
            });
        }
    };

    for item in &header.structs {
        for field in &item.fields {
            push(&item.name, &field.name, &field.ty, &mut out);
        }
        for method in &item.methods {
            for param in &method.params {
                push(&item.name, &method.name, &param.ty, &mut out);
            }
        }
    }
    for class in &header.classes {
        for ctor in &class.constructors {
            for param in &ctor.params {
                push(&class.name, &ctor_member_name(class, ctor), &param.ty, &mut out);
            }
        }
        for method in &class.methods {
            for param in &method.params {
                push(&class.name, &method.name, &param.ty, &mut out);
            }
        }
    }
    out
}

/// Callback typedefs for constructor parameters are named after the C symbol
/// the constructor produces, so overloads do not collide.
fn ctor_member_name(class: &Class, ctor: &Constructor) -> String {
    match codegen_shared::naming::constructor_suffix(class, ctor) {
        Some(suffix) => format!("create_{}", suffix.to_snake_case()),
        None => "create".to_string(),
    }
}

fn render_callback_typedef(out: &mut String, decl: &CallbackDecl, prefix: &str) {
    let mut params: Vec<String> = decl
        .params
        .iter()
        .enumerate()
        .map(|(index, ty)| format!("{} arg{index}", c_param_type(ty, prefix)))
        .collect();
    params.push("void* user_data".to_string());
    writeln!(out, "typedef void (*{})({});", decl.name, params.join(", ")).unwrap();
    writeln!(out).unwrap();
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

fn render_c_event_types(out: &mut String, group: &EventGroup, prefix: &str) {
    let type_enum = c_event_type_enum(prefix, &group.name);
    writeln!(out, "/// Which concrete {} arrived.", group.name).unwrap();
    writeln!(out, "typedef enum {{").unwrap();
    for (index, variant) in group.variants.iter().enumerate() {
        writeln!(
            out,
            "  {} = {index},",
            c_event_variant(prefix, &group.name, &variant.discriminant)
        )
        .unwrap();
    }
    writeln!(out, "}} {type_enum};").unwrap();
    writeln!(out).unwrap();

    writeln!(out, "/// One {}, tagged by its concrete type.", group.name).unwrap();
    writeln!(out, "///").unwrap();
    writeln!(
        out,
        "/// Valid only for the duration of the callback: anything it points at"
    )
    .unwrap();
    writeln!(
        out,
        "/// is released as soon as the callback returns. Copy what you need."
    )
    .unwrap();
    writeln!(out, "typedef struct {{").unwrap();
    writeln!(out, "  {type_enum} type;").unwrap();
    for field in &group.common {
        writeln!(
            out,
            "  {} {};",
            c_field_type(&field.ty, prefix),
            field.name.to_snake_case()
        )
        .unwrap();
    }
    let payloads: Vec<_> = group
        .variants
        .iter()
        .filter(|variant| !variant.fields.is_empty())
        .collect();
    if !payloads.is_empty() {
        writeln!(out, "  union {{").unwrap();
        for variant in payloads {
            writeln!(out, "    struct {{").unwrap();
            for field in &variant.fields {
                writeln!(
                    out,
                    "      {} {};",
                    c_field_type(&field.ty, prefix),
                    field.name.to_snake_case()
                )
                .unwrap();
            }
            writeln!(
                out,
                "    }} {};",
                c_event_variant_field(&variant.discriminant)
            )
            .unwrap();
        }
        writeln!(out, "  }} data;").unwrap();
    }
    writeln!(out, "}} {};", c_type_name(prefix, &group.name)).unwrap();
    writeln!(out).unwrap();

    writeln!(
        out,
        "typedef void (*{})(const {}* event, void* user_data);",
        c_event_callback_type(prefix, &group.name),
        c_type_name(prefix, &group.name)
    )
    .unwrap();
    writeln!(out).unwrap();
}

/// C++-only declarations that let another translation unit turn a live C++
/// event into the C struct. Kept out of `extern "C"` on purpose: they take C++
/// references and are never called from C.
fn render_cpp_bridge_decl(out: &mut String, header: &Header, prefix: &str) {
    if header.events.is_empty() {
        return;
    }
    writeln!(out).unwrap();
    writeln!(out, "#ifdef __cplusplus").unwrap();
    writeln!(out, "namespace nativeapi {{").unwrap();
    for group in &header.events {
        writeln!(out, "class {};", group.name).unwrap();
    }
    writeln!(out, "}}  // namespace nativeapi").unwrap();
    writeln!(out).unwrap();
    for group in &header.events {
        writeln!(
            out,
            "/// Fills @p out from @p event. Returns false when the event is not one"
        )
        .unwrap();
        writeln!(out, "/// of the concrete types the C ABI knows about.").unwrap();
        writeln!(
            out,
            "bool {}(const {}& event, {}* out);",
            cpp_event_converter(&group.name),
            group.qualified_name,
            c_type_name(prefix, &group.name)
        )
        .unwrap();
        writeln!(
            out,
            "/// Releases everything {}() allocated.",
            cpp_event_converter(&group.name)
        )
        .unwrap();
        writeln!(
            out,
            "void {}({}* value);",
            cpp_event_releaser(&group.name),
            c_type_name(prefix, &group.name)
        )
        .unwrap();
        writeln!(out).unwrap();
    }
    writeln!(out, "#endif").unwrap();
}

// ---------------------------------------------------------------------------
// Source
// ---------------------------------------------------------------------------

fn render_c_source(
    api: &Api,
    header: &Header,
    origins: &TypeOrigins,
    listed: &BTreeSet<String>,
    capi_out: &Path,
    prefix: &str,
    c_header_name: &str,
) -> String {
    // Converters now live in the shared header; only the C++ declarations of
    // borrowed types still have to be pulled in here.
    let (_, _, imported_headers) = imported_types(api, header, origins);
    let source_include = relative_include(capi_out, &header.path);
    let mut out = String::new();
    write_banner(&mut out);
    writeln!(out, "#include \"{}\"", c_header_name).unwrap();
    writeln!(out).unwrap();

    writeln!(out, "#include <cstdio>").unwrap();
    writeln!(out, "#include <memory>").unwrap();
    writeln!(out, "#include <new>").unwrap();
    writeln!(out, "#include <optional>").unwrap();
    writeln!(out, "#include <string>").unwrap();
    writeln!(out, "#include <utility>").unwrap();
    writeln!(out, "#include <vector>").unwrap();
    writeln!(out).unwrap();

    writeln!(
        out,
        "#include \"{}\"",
        codegen_shared::naming::STRING_UTILS_HEADER
    )
    .unwrap();
    writeln!(out, "#include \"{USER_DATA_HEADER}\"").unwrap();
    writeln!(
        out,
        "#include \"{}\"",
        relative_include(capi_out, &handle_table_path(&header.path))
    )
    .unwrap();
    // C++ declarations of types owned by other headers.
    for other in &imported_headers {
        writeln!(
            out,
            "#include \"{}\"",
            relative_include(capi_out, &other.path)
        )
        .unwrap();
        writeln!(out, "#include \"{}_c.h\"", other.stem).unwrap();
    }
    writeln!(out, "#include \"{}\"", source_include).unwrap();
    writeln!(out).unwrap();

    for item in &header.structs {
        render_struct_api(&mut out, item, prefix);
    }

    for class in &header.classes {
        for ctor in &class.constructors {
            render_c_constructor(&mut out, class, ctor, prefix);
        }
        for method in &class.methods {
            render_c_method(&mut out, header, class, method, prefix);
        }
        if class.is_instance() {
            render_c_handle_functions(&mut out, class, listed.contains(&class.name), prefix);
        }
        render_listener_impl(&mut out, api, class, prefix);
    }

    for group in &header.events {
        render_event_bridge(&mut out, group, prefix);
    }

    out
}

/// `src/foundation/handle_table.h`, derived from the header being generated for
/// so the include stays relative to `src/capi/`.
fn handle_table_path(header: &Path) -> std::path::PathBuf {
    let mut dir = header.parent().unwrap_or(Path::new(".")).to_path_buf();
    // Headers live either in `src/` or `src/foundation/`.
    if dir.file_name().and_then(|name| name.to_str()) == Some("foundation") {
        dir.pop();
    }
    dir.join("foundation").join("handle_table.h")
}

/// Stand-in for the enclosing header when rendering something that cannot name
/// enum fallbacks anyway (constructors, struct helpers).
fn empty_header() -> Header {
    Header {
        path: Default::default(),
        stem: String::new(),
        namespace: String::new(),
        enums: Vec::new(),
        structs: Vec::new(),
        classes: Vec::new(),
        aliases: Vec::new(),
        events: Vec::new(),
    }
}

/// Where a module's C++ <-> C converters live.
fn write_banner(out: &mut String) {
    writeln!(out, "// AUTO-GENERATED. DO NOT EDIT.").unwrap();
    writeln!(
        out,
        "// Any manual changes WILL BE LOST when this file is regenerated."
    )
    .unwrap();
    writeln!(out).unwrap();
}

fn render_c_enum_converter(out: &mut String, item: &Enum, prefix: &str) {
    writeln!(
        out,
        "inline {} {}({} value) {{",
        c_type_name(prefix, &item.name),
        cpp_to_c_fn(&item.name),
        item.qualified_name
    )
    .unwrap();
    writeln!(out, "  switch (value) {{").unwrap();
    for variant in &item.variants {
        writeln!(out, "    case {}::{}:", item.qualified_name, variant.name).unwrap();
        writeln!(
            out,
            "      return {};",
            c_enum_variant(prefix, item, &variant.name)
        )
        .unwrap();
    }
    writeln!(out, "    default:").unwrap();
    let fallback = item
        .variants
        .first()
        .map(|variant| c_enum_variant(prefix, item, &variant.name))
        .unwrap_or_else(|| "0".to_string());
    writeln!(out, "      return {};", fallback).unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

fn render_cpp_enum_converter(out: &mut String, item: &Enum, prefix: &str) {
    writeln!(
        out,
        "inline {} {}({} value) {{",
        item.qualified_name,
        c_to_cpp_fn(&item.name),
        c_type_name(prefix, &item.name)
    )
    .unwrap();
    writeln!(out, "  switch (value) {{").unwrap();
    for variant in &item.variants {
        writeln!(
            out,
            "    case {}:",
            c_enum_variant(prefix, item, &variant.name)
        )
        .unwrap();
        writeln!(
            out,
            "      return {}::{};",
            item.qualified_name, variant.name
        )
        .unwrap();
    }
    writeln!(out, "    default:").unwrap();
    let fallback = item
        .variants
        .first()
        .map(|variant| format!("{}::{}", item.qualified_name, variant.name))
        .unwrap_or_else(|| "{}".to_string());
    writeln!(out, "      return {};", fallback).unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

fn render_c_struct_converter(out: &mut String, item: &Struct, prefix: &str) {
    writeln!(
        out,
        "inline {} {}(const {}& value) {{",
        c_type_name(prefix, &item.name),
        cpp_to_c_fn(&item.name),
        item.qualified_name
    )
    .unwrap();
    writeln!(out, "  {} result = {{}};", c_type_name(prefix, &item.name)).unwrap();
    for field in &item.fields {
        let c_name = field.name.to_snake_case();
        match &field.ty {
            TypeRef::String => {
                writeln!(
                    out,
                    "  result.{c_name} = {STRING_DUP_FN}(value.{});",
                    field.name
                )
                .unwrap();
            }
            TypeRef::Enum { name, .. } => {
                writeln!(out, "  result.{c_name} = {}(value.{});", cpp_to_c_fn(name), field.name).unwrap();
            }
            TypeRef::Struct { name, .. } => {
                writeln!(out, "  result.{c_name} = {}(value.{});", cpp_to_c_fn(name), field.name).unwrap();
            }
            // A callback field has no meaningful C++ -> C direction: the C side
            // supplies it, never receives it.
            TypeRef::Callback { .. } | TypeRef::Optional { .. } => {}
            _ => {
                writeln!(out, "  result.{c_name} = value.{};", field.name).unwrap();
            }
        }
    }
    writeln!(out, "  return result;").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

fn render_cpp_struct_converter(out: &mut String, item: &Struct, prefix: &str) {
    writeln!(
        out,
        "inline {} {}(const {}& value) {{",
        item.qualified_name,
        c_to_cpp_fn(&item.name),
        c_type_name(prefix, &item.name)
    )
    .unwrap();
    writeln!(out, "  {} result = {{}};", item.qualified_name).unwrap();
    for field in &item.fields {
        let c_name = field.name.to_snake_case();
        match &field.ty {
            TypeRef::String => {
                writeln!(
                    out,
                    "  result.{} = value.{c_name} ? value.{c_name} : \"\";",
                    field.name
                )
                .unwrap();
            }
            TypeRef::Enum { name, .. } | TypeRef::Struct { name, .. } => {
                writeln!(
                    out,
                    "  result.{} = {}(value.{c_name});",
                    field.name,
                    c_to_cpp_fn(name)
                )
                .unwrap();
            }
            TypeRef::Callback { .. } => {
                let user_data = codegen_shared::naming::c_user_data_param(&field.name);
                let release = c_release_user_data_param(&field.name);
                // Created unconditionally, so a NULL callback still releases.
                writeln!(
                    out,
                    "  auto {c_name}_holder = nativeapi::capi::UserData::Make(value.{user_data}, value.{release});"
                )
                .unwrap();
                writeln!(out, "  if (value.{c_name}) {{").unwrap();
                writeln!(out, "    auto callback = value.{c_name};").unwrap();
                writeln!(
                    out,
                    "    result.{} = [callback, holder = {c_name}_holder]() {{ callback(holder->get()); }};",
                    field.name
                )
                .unwrap();
                writeln!(out, "  }}").unwrap();
            }
            TypeRef::Optional { .. } => {}
            _ => {
                writeln!(out, "  result.{} = value.{c_name};", field.name).unwrap();
            }
        }
    }
    writeln!(out, "  return result;").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

// ---------------------------------------------------------------------------
// Method bodies
// ---------------------------------------------------------------------------

/// Locals the call site needs: resolved handles, converted containers, wrapped
/// callbacks. Returns false out of the function when a required handle is
/// stale, which is what makes an invalid handle safe rather than fatal.
fn render_param_bindings(
    out: &mut String,
    header: &Header,
    params: &[Param],
    prefix: &str,
    fail_return: &dyn Fn(&mut String, &str),
    indent: &str,
) {
    for param in params {
        let name = param.name.to_snake_case();
        match &param.ty {
            TypeRef::Object {
                name: type_name,
                qualified_name,
                shared,
            } => {
                writeln!(
                    out,
                    "{indent}auto {name}_cpp = nativeapi::HandleTable::GetInstance().Resolve<{qualified_name}>({name});"
                )
                .unwrap();
                // A shared parameter may legitimately be null (clearing an icon,
                // for instance); a by-value one is about to be dereferenced.
                if !shared {
                    writeln!(out, "{indent}if (!{name}_cpp) {{").unwrap();
                    let _ = type_name;
                    fail_return(out, indent);
                    writeln!(out, "{indent}}}").unwrap();
                }
            }
            TypeRef::Struct { name: type_name, .. } => {
                writeln!(
                    out,
                    "{indent}auto {name}_cpp = {}({name});",
                    c_to_cpp_fn(type_name)
                )
                .unwrap();
            }
            TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
                writeln!(
                    out,
                    "{indent}std::vector<std::string> {name}_cpp;\n{indent}for (long i = 0; i < {name}.count; ++i) {{\n{indent}  {name}_cpp.emplace_back({name}.items[i] ? {name}.items[i] : \"\");\n{indent}}}"
                )
                .unwrap();
            }
            TypeRef::Map { .. } => {
                writeln!(
                    out,
                    "{indent}std::map<std::string, std::string> {name}_cpp;\n{indent}for (long i = 0; i < {name}.count; ++i) {{\n{indent}  {name}_cpp[{name}.entries[i].key ? {name}.entries[i].key : \"\"] =\n{indent}      {name}.entries[i].value ? {name}.entries[i].value : \"\";\n{indent}}}"
                )
                .unwrap();
            }
            TypeRef::Optional { inner } => render_optional_binding(out, &name, inner, indent),
            TypeRef::Callback { params: args } => {
                render_callback_binding(out, &name, args, indent, /* optional */ false);
            }
            _ => {}
        }
    }
    let _ = (header, prefix);
}

fn render_optional_binding(out: &mut String, name: &str, inner: &TypeRef, indent: &str) {
    match inner {
        TypeRef::String => {
            writeln!(
                out,
                "{indent}std::optional<std::string> {name}_cpp;\n{indent}if ({name}) {{\n{indent}  {name}_cpp = std::string({name});\n{indent}}}"
            )
            .unwrap();
        }
        TypeRef::Object { qualified_name, .. } => {
            writeln!(
                out,
                "{indent}auto {name}_cpp = nativeapi::HandleTable::GetInstance().Resolve<{qualified_name}>({name});"
            )
            .unwrap();
        }
        TypeRef::Struct {
            name: type_name,
            qualified_name,
        } => {
            writeln!(
                out,
                "{indent}std::optional<{qualified_name}> {name}_cpp;\n{indent}if ({name}) {{\n{indent}  {name}_cpp = {}(*{name});\n{indent}}}",
                c_to_cpp_fn(type_name)
            )
            .unwrap();
        }
        TypeRef::Callback { params } => {
            render_callback_binding(out, name, params, indent, /* optional */ true);
        }
        _ => {}
    }
}

/// Takes ownership of each callback's `user_data` before anything can fail, so
/// every early return still releases it (see `user_data.h`).
fn render_user_data_holders(out: &mut String, params: &[Param]) {
    for param in params.iter().filter(|param| is_callback(&param.ty)) {
        let name = param.name.to_snake_case();
        writeln!(
            out,
            "  auto {name}_holder = nativeapi::capi::UserData::Make({}, {});",
            codegen_shared::naming::c_user_data_param(&param.name),
            c_release_user_data_param(&param.name)
        )
        .unwrap();
    }
}

/// Wraps a C function pointer plus its `user_data` holder into the
/// `std::function` the C++ API expects.
fn render_callback_binding(
    out: &mut String,
    name: &str,
    params: &[TypeRef],
    indent: &str,
    optional: bool,
) {
    let user_data = format!("{name}_holder->get()");
    let holder = format!("{name}_holder");
    let args: Vec<String> = params
        .iter()
        .enumerate()
        .map(|(index, _)| format!("arg{index}"))
        .collect();
    let lambda_params: Vec<String> = params
        .iter()
        .enumerate()
        .map(|(index, ty)| format!("{} arg{index}", cpp_lambda_param(ty)))
        .collect();

    if optional {
        writeln!(out, "{indent}std::optional<std::function<void({})>> {name}_cpp;", params.iter().map(cpp_lambda_param).collect::<Vec<_>>().join(", ")).unwrap();
        writeln!(out, "{indent}if ({name}) {{").unwrap();
        writeln!(
            out,
            "{indent}  {name}_cpp = [{name}, {holder}]({}) {{ {name}({}); }};",
            lambda_params.join(", "),
            args.iter()
                .cloned()
                .chain(std::iter::once(user_data.clone()))
                .collect::<Vec<_>>()
                .join(", ")
        )
        .unwrap();
        writeln!(out, "{indent}}}").unwrap();
        return;
    }

    writeln!(
        out,
        "{indent}std::function<void({})> {name}_cpp;",
        params
            .iter()
            .map(cpp_lambda_param)
            .collect::<Vec<_>>()
            .join(", ")
    )
    .unwrap();
    writeln!(out, "{indent}if ({name}) {{").unwrap();
    writeln!(
        out,
        "{indent}  {name}_cpp = [{name}, {holder}]({}) {{ {name}({}); }};",
        lambda_params.join(", "),
        args.iter()
            .cloned()
            .chain(std::iter::once(user_data.clone()))
            .collect::<Vec<_>>()
            .join(", ")
    )
    .unwrap();
    writeln!(out, "{indent}}}").unwrap();
}

/// C++ spelling of a callback argument. The callback receives the same C types
/// the function pointer declares, so no conversion happens at the boundary.
fn cpp_lambda_param(ty: &TypeRef) -> String {
    match ty {
        TypeRef::Bool => "bool".to_string(),
        TypeRef::Int { name } => name.clone(),
        TypeRef::Float { name } => name.clone(),
        _ => "int".to_string(),
    }
}

fn render_c_method(
    out: &mut String,
    header: &Header,
    class: &Class,
    method: &Method,
    prefix: &str,
) {
    let symbol = c_method_symbol(prefix, class, method);
    let instance = class.is_instance() && !method.is_static;

    writeln!(
        out,
        "{} {}({}) {{",
        c_return_type(&method.return_type, prefix),
        symbol,
        c_params(method, Some(class), prefix)
    )
    .unwrap();

    let return_type = method.return_type.clone();
    let header_ref = header;
    let fail = move |out: &mut String, indent: &str| {
        render_c_default_return(out, header_ref, &return_type, prefix, indent);
    };

    render_user_data_holders(out, &method.params);
    if instance {
        let self_param = c_self_param(class);
        writeln!(
            out,
            "  auto self = nativeapi::HandleTable::GetInstance().Resolve<{}>({self_param});",
            class.qualified_name
        )
        .unwrap();
        writeln!(out, "  if (!self) {{").unwrap();
        fail(out, "  ");
        writeln!(out, "  }}").unwrap();
    }

    writeln!(out, "  try {{").unwrap();
    render_param_bindings(out, header, &method.params, prefix, &fail, "    ");

    let receiver = if instance {
        "self->".to_string()
    } else if class.is_singleton() {
        format!("{}::GetInstance().", class.qualified_name)
    } else {
        format!("{}::", class.qualified_name)
    };
    let call = format!("{receiver}{}({})", method.name, c_call_args(method));

    render_return(out, &method.return_type, &call, prefix, "    ");

    writeln!(out, "  }} catch (...) {{").unwrap();
    writeln!(
        out,
        "    fprintf(stderr, \"[nativeapi] %s: unexpected exception\\n\", \"{}\");",
        symbol
    )
    .unwrap();
    fail(out, "  ");
    writeln!(out, "  }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

/// Emits the `return` for one call, converting the C++ result to its C form.
fn render_return(out: &mut String, ty: &TypeRef, call: &str, prefix: &str, indent: &str) {
    match ty {
        TypeRef::Void => {
            writeln!(out, "{indent}{call};").unwrap();
            writeln!(out, "{indent}return;").unwrap();
        }
        TypeRef::String => {
            writeln!(out, "{indent}return {STRING_DUP_FN}({call});").unwrap();
        }
        TypeRef::Struct { name, .. } => {
            writeln!(out, "{indent}const auto cpp_result = {call};").unwrap();
            writeln!(out, "{indent}return {}(cpp_result);", cpp_to_c_fn(name)).unwrap();
        }
        TypeRef::Enum { name, .. } => {
            writeln!(out, "{indent}return {}({call});", cpp_to_c_fn(name)).unwrap();
        }
        // Both shapes end up owning a `shared_ptr` in the handle table; a
        // by-value result just has to be moved into one first.
        TypeRef::Object {
            qualified_name,
            shared,
            ..
        } => {
            if *shared {
                writeln!(out, "{indent}return nativeapi::HandleTable::GetInstance().Insert({call});")
                    .unwrap();
            } else {
                writeln!(
                    out,
                    "{indent}return nativeapi::HandleTable::GetInstance().Insert(\n{indent}    std::make_shared<{qualified_name}>({call}));"
                )
                .unwrap();
            }
        }
        TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
            writeln!(out, "{indent}return {STRING_LIST_DUP_FN}({call});").unwrap();
        }
        TypeRef::Vector { element } => {
            render_c_list_return(out, element, prefix, call, indent);
        }
        TypeRef::Map { .. } => {
            writeln!(out, "{indent}return {STRING_MAP_DUP_FN}({call});").unwrap();
        }
        TypeRef::Optional { inner } => match inner.as_ref() {
            TypeRef::String => {
                writeln!(out, "{indent}const auto cpp_result = {call};").unwrap();
                writeln!(
                    out,
                    "{indent}return cpp_result ? {STRING_DUP_FN}(*cpp_result) : nullptr;"
                )
                .unwrap();
            }
            TypeRef::Object { .. } => {
                writeln!(out, "{indent}const auto cpp_result = {call};").unwrap();
                writeln!(
                    out,
                    "{indent}return cpp_result\n{indent}    ? nativeapi::HandleTable::GetInstance().Insert(*cpp_result)\n{indent}    : 0;"
                )
                .unwrap();
            }
            _ => writeln!(out, "{indent}return {call};").unwrap(),
        },
        _ => {
            writeln!(out, "{indent}return {call};").unwrap();
        }
    }
}

/// `std::vector<Display>` -> `native_display_list_t` of fresh handles.
fn render_c_list_return(
    out: &mut String,
    element: &TypeRef,
    prefix: &str,
    call: &str,
    indent: &str,
) {
    let (name, qualified_name, shared) = match element {
        TypeRef::Object {
            name,
            qualified_name,
            shared,
        } => (name, qualified_name, *shared),
        _ => return,
    };
    let list_type = c_list_type_name(prefix, name);
    let handle = c_type_name(prefix, name);
    let field = c_list_field(name);

    writeln!(out, "{indent}const auto items = {call};").unwrap();
    writeln!(out, "{indent}{list_type} list = {{}};").unwrap();
    writeln!(out, "{indent}if (items.empty()) {{").unwrap();
    writeln!(out, "{indent}  return list;").unwrap();
    writeln!(out, "{indent}}}").unwrap();
    writeln!(
        out,
        "{indent}list.{field} = new (std::nothrow) {handle}[items.size()];"
    )
    .unwrap();
    writeln!(out, "{indent}if (!list.{field}) {{").unwrap();
    writeln!(out, "{indent}  return list;").unwrap();
    writeln!(out, "{indent}}}").unwrap();
    writeln!(out, "{indent}for (size_t i = 0; i < items.size(); ++i) {{").unwrap();
    if shared {
        writeln!(
            out,
            "{indent}  list.{field}[i] = nativeapi::HandleTable::GetInstance().Insert(items[i]);"
        )
        .unwrap();
    } else {
        writeln!(
            out,
            "{indent}  list.{field}[i] = nativeapi::HandleTable::GetInstance().Insert(\n{indent}      std::make_shared<{qualified_name}>(items[i]));"
        )
        .unwrap();
    }
    writeln!(out, "{indent}}}").unwrap();
    writeln!(out, "{indent}list.count = static_cast<long>(items.size());").unwrap();
    writeln!(out, "{indent}return list;").unwrap();
}

fn render_c_default_return(
    out: &mut String,
    header: &Header,
    ty: &TypeRef,
    prefix: &str,
    indent: &str,
) {
    match ty {
        TypeRef::Void => writeln!(out, "{indent}  return;").unwrap(),
        TypeRef::Bool => writeln!(out, "{indent}  return false;").unwrap(),
        TypeRef::Int { .. } | TypeRef::Float { .. } => writeln!(out, "{indent}  return 0;").unwrap(),
        TypeRef::Object { .. } => writeln!(out, "{indent}  return 0;").unwrap(),
        TypeRef::Enum { name, .. } => {
            let fallback = header
                .enums
                .iter()
                .find(|item| item.name == *name)
                .and_then(|item| {
                    item.variants
                        .first()
                        .map(|variant| c_enum_variant(prefix, item, &variant.name))
                })
                .unwrap_or_else(|| "0".to_string());
            writeln!(out, "{indent}  return ({}){};", c_type_name(prefix, name), fallback).unwrap();
        }
        TypeRef::Struct { name, .. } => {
            writeln!(out, "{indent}  {} result = {{}};", c_type_name(prefix, name)).unwrap();
            if let Some(item) = header.structs.iter().find(|item| item.name == *name) {
                for field in &item.fields {
                    match field.name.as_str() {
                        "success" if matches!(field.ty, TypeRef::Bool) => {
                            writeln!(out, "{indent}  result.success = false;").unwrap();
                        }
                        _ => {}
                    }
                }
            }
            writeln!(out, "{indent}  return result;").unwrap();
        }
        TypeRef::Vector { element } => {
            let list_type = match element.as_ref() {
                TypeRef::Object { name, .. } => c_list_type_name(prefix, name),
                TypeRef::String => STRING_LIST_TYPE.to_string(),
                _ => "void*".to_string(),
            };
            writeln!(out, "{indent}  {list_type} empty = {{}};").unwrap();
            writeln!(out, "{indent}  return empty;").unwrap();
        }
        TypeRef::Map { .. } => {
            writeln!(out, "{indent}  {STRING_MAP_TYPE} empty = {{}};").unwrap();
            writeln!(out, "{indent}  return empty;").unwrap();
        }
        TypeRef::Optional { inner } => render_c_default_return(out, header, inner, prefix, indent),
        TypeRef::Alias { underlying, .. } => {
            render_c_default_return(out, header, underlying, prefix, indent)
        }
        TypeRef::String | TypeRef::CString | TypeRef::RawPointer | TypeRef::Callback { .. } => {
            writeln!(out, "{indent}  return nullptr;").unwrap()
        }
        TypeRef::Unsupported { .. } => writeln!(out, "{indent}  return {{}};").unwrap(),
    }
}

fn c_ctor_params(class: &Class, ctor: &Constructor, prefix: &str) -> String {
    let params = c_param_list(
        &ctor.params,
        prefix,
        &class.name,
        &ctor_member_name(class, ctor),
    );
    if params.is_empty() {
        return "void".to_string();
    }
    params.join(", ")
}

fn render_c_constructor(
    out: &mut String,
    class: &Class,
    ctor: &Constructor,
    prefix: &str,
) {
    let symbol = c_constructor_symbol(prefix, class, ctor);
    writeln!(
        out,
        "{} {symbol}({}) {{",
        c_type_name(prefix, &class.name),
        c_ctor_params(class, ctor, prefix)
    )
    .unwrap();
    render_user_data_holders(out, &ctor.params);
    writeln!(out, "  try {{").unwrap();
    let fail = |out: &mut String, indent: &str| {
        writeln!(out, "{indent}  return 0;").unwrap();
    };
    render_param_bindings(out, &empty_header(), &ctor.params, prefix, &fail, "    ");
    writeln!(
        out,
        "    return nativeapi::HandleTable::GetInstance().Insert(\n        std::make_shared<{}>({}));",
        class.qualified_name,
        ctor_call_args(ctor)
    )
    .unwrap();
    writeln!(out, "  }} catch (...) {{").unwrap();
    writeln!(
        out,
        "    fprintf(stderr, \"[nativeapi] %s: unexpected exception\\n\", \"{symbol}\");"
    )
    .unwrap();
    writeln!(out, "    return 0;").unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

fn ctor_call_args(ctor: &Constructor) -> String {
    ctor.params
        .iter()
        .map(|param| cpp_argument_expr(&param.ty, &param.name))
        .collect::<Vec<_>>()
        .join(", ")
}

fn render_c_handle_functions(out: &mut String, class: &Class, listed: bool, prefix: &str) {
    let handle = c_type_name(prefix, &class.name);
    let self_param = c_self_param(class);
    let cpp = &class.qualified_name;
    let list_type = c_list_type_name(prefix, &class.name);
    let field = c_list_field(&class.name);

    if class.native_object {
        writeln!(
            out,
            "void* {}({handle} {self_param}) {{",
            c_native_object_symbol(prefix, &class.name)
        )
        .unwrap();
        writeln!(
            out,
            "  auto self = nativeapi::HandleTable::GetInstance().Resolve<{cpp}>({self_param});"
        )
        .unwrap();
        writeln!(out, "  if (!self) {{").unwrap();
        writeln!(out, "    return nullptr;").unwrap();
        writeln!(out, "  }}").unwrap();
        writeln!(out, "  return self->GetNativeObject();").unwrap();
        writeln!(out, "}}").unwrap();
        writeln!(out).unwrap();
    }

    writeln!(
        out,
        "void {}({handle} {self_param}) {{",
        c_free_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(
        out,
        "  // The table invalidates the handle itself, so releasing an unknown or"
    )
    .unwrap();
    writeln!(out, "  // already-released one is a no-op rather than a double free.").unwrap();
    writeln!(
        out,
        "  nativeapi::HandleTable::GetInstance().Release({self_param});"
    )
    .unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    if !listed {
        return;
    }

    writeln!(
        out,
        "void {}({list_type}* list) {{",
        c_list_free_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(out, "  if (!list || !list->{field}) {{").unwrap();
    writeln!(out, "    return;").unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "  for (long i = 0; i < list->count; ++i) {{").unwrap();
    writeln!(
        out,
        "    nativeapi::HandleTable::GetInstance().Release(list->{field}[i]);"
    )
    .unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "  delete[] list->{field};").unwrap();
    writeln!(out, "  list->{field} = nullptr;").unwrap();
    writeln!(out, "  list->count = 0;").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    writeln!(
        out,
        "void {}({list_type}* list) {{",
        c_list_release_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(out, "  if (!list) {{").unwrap();
    writeln!(out, "    return;").unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "  delete[] list->{field};").unwrap();
    writeln!(out, "  list->{field} = nullptr;").unwrap();
    writeln!(out, "  list->count = 0;").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

/// Struct constants, static factories and const accessors.
fn render_struct_api(out: &mut String, item: &Struct, prefix: &str) {
    let c_name = c_type_name(prefix, &item.name);

    for constant in &item.constants {
        writeln!(
            out,
            "const {c_name} {} = {}({}::{constant});",
            c_struct_constant(prefix, &item.name, constant),
            cpp_to_c_fn(&item.name),
            item.qualified_name
        )
        .unwrap();
        writeln!(out).unwrap();
    }

    for method in &item.methods {
        let symbol = c_struct_method_symbol(prefix, item, method);
        writeln!(
            out,
            "{} {symbol}({}) {{",
            c_return_type(&method.return_type, prefix),
            c_struct_method_params(item, method, prefix)
        )
        .unwrap();
        writeln!(out, "  try {{").unwrap();
        let receiver = if method.is_static {
            format!("{}::", item.qualified_name)
        } else {
            writeln!(
                out,
                "    const auto self = {}({});",
                c_to_cpp_fn(&item.name),
                item.name.to_snake_case()
            )
            .unwrap();
            "self.".to_string()
        };
        let scratch = empty_header();
        let return_type = method.return_type.clone();
        let fail = |out: &mut String, indent: &str| {
            render_c_default_return(out, &scratch, &return_type, prefix, indent);
        };
        render_param_bindings(out, &scratch, &method.params, prefix, &fail, "    ");
        let call = format!("{receiver}{}({})", method.name, c_call_args(method));
        render_return(out, &method.return_type, &call, prefix, "    ");
        writeln!(out, "  }} catch (...) {{").unwrap();
        writeln!(
            out,
            "    fprintf(stderr, \"[nativeapi] %s: unexpected exception\\n\", \"{symbol}\");"
        )
        .unwrap();
        fail(out, "  ");
        writeln!(out, "  }}").unwrap();
        writeln!(out, "}}").unwrap();
        writeln!(out).unwrap();
    }

    if struct_has_owned_fields(item) {
        render_c_free(out, item, prefix);
    }
}

fn render_c_free(out: &mut String, item: &Struct, prefix: &str) {
    writeln!(
        out,
        "void {}({}* value) {{",
        c_free_symbol(prefix, &item.name),
        c_type_name(prefix, &item.name)
    )
    .unwrap();
    writeln!(out, "  if (!value) {{").unwrap();
    writeln!(out, "    return;").unwrap();
    writeln!(out, "  }}").unwrap();
    for field in &item.fields {
        if matches!(field.ty, TypeRef::String) {
            let name = field.name.to_snake_case();
            writeln!(out, "  {STRING_FREE_FN}(value->{name});").unwrap();
            writeln!(out, "  value->{name} = nullptr;").unwrap();
        }
    }
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

// ---------------------------------------------------------------------------
// Event bridging
// ---------------------------------------------------------------------------

fn render_listener_impl(out: &mut String, api: &Api, class: &Class, prefix: &str) {
    let Some(group) = emitted_group(api, class) else {
        return;
    };
    let callback_type = c_event_callback_type(prefix, &group.name);
    let event_type = c_type_name(prefix, &group.name);
    let receiver_param = listener_receiver_param(class, prefix);
    let instance = class.is_instance();

    // add_listener
    writeln!(
        out,
        "{LISTENER_ID_TYPE} {}({receiver_param}{callback_type} callback, void* user_data, {RELEASE_USER_DATA_TYPE} release_user_data) {{",
        c_add_listener_symbol(prefix, &class.name)
    )
    .unwrap();
    // First, so every failure below still releases user_data.
    writeln!(
        out,
        "  auto holder = nativeapi::capi::UserData::Make(user_data, release_user_data);"
    )
    .unwrap();
    writeln!(out, "  if (!callback) {{").unwrap();
    writeln!(out, "    return 0;").unwrap();
    writeln!(out, "  }}").unwrap();
    let receiver = render_emitter_receiver(out, class, instance, "  ", "0");
    writeln!(out, "  try {{").unwrap();
    writeln!(
        out,
        "    return static_cast<{LISTENER_ID_TYPE}>({receiver}AddListener<{}>(",
        group.qualified_name
    )
    .unwrap();
    writeln!(
        out,
        "        [callback, holder](const {}& event) {{",
        group.qualified_name
    )
    .unwrap();
    writeln!(out, "          {event_type} c_event = {{}};").unwrap();
    writeln!(
        out,
        "          if (!{}(event, &c_event)) {{",
        cpp_event_converter(&group.name)
    )
    .unwrap();
    writeln!(out, "            return;").unwrap();
    writeln!(out, "          }}").unwrap();
    writeln!(out, "          callback(&c_event, holder->get());").unwrap();
    writeln!(
        out,
        "          {}(&c_event);",
        cpp_event_releaser(&group.name)
    )
    .unwrap();
    writeln!(out, "        }}));").unwrap();
    writeln!(out, "  }} catch (...) {{").unwrap();
    writeln!(out, "    return 0;").unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    // remove_listener
    writeln!(
        out,
        "bool {}({receiver_param}{LISTENER_ID_TYPE} listener_id) {{",
        c_remove_listener_symbol(prefix, &class.name)
    )
    .unwrap();
    let receiver = render_emitter_receiver(out, class, instance, "  ", "false");
    writeln!(out, "  try {{").unwrap();
    writeln!(
        out,
        "    return {receiver}RemoveListener(static_cast<size_t>(listener_id));"
    )
    .unwrap();
    writeln!(out, "  }} catch (...) {{").unwrap();
    writeln!(out, "    return false;").unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

/// Emits the lines that produce the emitter and returns the receiver prefix.
fn render_emitter_receiver(
    out: &mut String,
    class: &Class,
    instance: bool,
    indent: &str,
    fail_value: &str,
) -> String {
    if !instance {
        return format!("{}::GetInstance().", class.qualified_name);
    }
    let self_param = c_self_param(class);
    writeln!(
        out,
        "{indent}auto self = nativeapi::HandleTable::GetInstance().Resolve<{}>({self_param});",
        class.qualified_name
    )
    .unwrap();
    writeln!(out, "{indent}if (!self) {{").unwrap();
    writeln!(out, "{indent}  return {fail_value};").unwrap();
    writeln!(out, "{indent}}}").unwrap();
    "self->".to_string()
}

/// The C++ -> C converter for an event hierarchy, plus its releaser.
fn render_event_bridge(out: &mut String, group: &EventGroup, prefix: &str) {
    let c_name = c_type_name(prefix, &group.name);

    writeln!(
        out,
        "bool {}(const {}& event, {c_name}* out) {{",
        cpp_event_converter(&group.name),
        group.qualified_name
    )
    .unwrap();
    writeln!(out, "  if (!out) {{").unwrap();
    writeln!(out, "    return false;").unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "  *out = {c_name}{{}};").unwrap();
    for field in &group.common {
        render_event_field_assign(out, "out->", "event.", field, "  ");
    }
    for variant in &group.variants {
        writeln!(
            out,
            "  if (const auto* typed = dynamic_cast<const {}*>(&event)) {{",
            variant.qualified_name
        )
        .unwrap();
        writeln!(
            out,
            "    out->type = {};",
            c_event_variant(prefix, &group.name, &variant.discriminant)
        )
        .unwrap();
        let target = format!("out->data.{}.", c_event_variant_field(&variant.discriminant));
        for field in &variant.fields {
            render_event_field_assign(out, &target, "typed->", field, "    ");
        }
        if variant.fields.is_empty() {
            writeln!(out, "    (void)typed;").unwrap();
        }
        writeln!(out, "    return true;").unwrap();
        writeln!(out, "  }}").unwrap();
    }
    writeln!(out, "  return false;").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    writeln!(
        out,
        "void {}({c_name}* value) {{",
        cpp_event_releaser(&group.name)
    )
    .unwrap();
    writeln!(out, "  if (!value) {{").unwrap();
    writeln!(out, "    return;").unwrap();
    writeln!(out, "  }}").unwrap();
    for field in &group.common {
        render_event_field_release(out, "value->", field, "  ");
    }
    for variant in &group.variants {
        if variant.fields.iter().all(|field| !event_field_owns(field)) {
            continue;
        }
        writeln!(
            out,
            "  if (value->type == {}) {{",
            c_event_variant(prefix, &group.name, &variant.discriminant)
        )
        .unwrap();
        let target = format!("value->data.{}.", c_event_variant_field(&variant.discriminant));
        for field in &variant.fields {
            render_event_field_release(out, &target, field, "    ");
        }
        writeln!(out, "  }}").unwrap();
    }
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

fn render_event_field_assign(
    out: &mut String,
    target: &str,
    source: &str,
    field: &Field,
    indent: &str,
) {
    let name = field.name.to_snake_case();
    let getter = format!("{source}Get{}()", field.name);
    match &field.ty {
        TypeRef::String => {
            writeln!(out, "{indent}{target}{name} = {STRING_DUP_FN}({getter});").unwrap();
        }
        TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
            writeln!(out, "{indent}{target}{name} = {STRING_LIST_DUP_FN}({getter});").unwrap();
        }
        TypeRef::Enum { name: type_name, .. } | TypeRef::Struct { name: type_name, .. } => {
            writeln!(
                out,
                "{indent}{target}{name} = {}({getter});",
                cpp_to_c_fn(type_name)
            )
            .unwrap();
        }
        TypeRef::Object { qualified_name, shared, .. } => {
            // The handle lives only as long as the callback; the releaser drops
            // it right after, so a listener that wants to keep it must resolve
            // and re-insert on its own.
            if *shared {
                writeln!(
                    out,
                    "{indent}{target}{name} = nativeapi::HandleTable::GetInstance().Insert({getter});"
                )
                .unwrap();
            } else {
                writeln!(
                    out,
                    "{indent}{target}{name} = nativeapi::HandleTable::GetInstance().Insert(\n{indent}    std::make_shared<{qualified_name}>({getter}));"
                )
                .unwrap();
            }
        }
        _ => {
            writeln!(out, "{indent}{target}{name} = {getter};").unwrap();
        }
    }
}

fn render_event_field_release(out: &mut String, target: &str, field: &Field, indent: &str) {
    let name = field.name.to_snake_case();
    match &field.ty {
        TypeRef::String => {
            writeln!(out, "{indent}{STRING_FREE_FN}({target}{name});").unwrap();
            writeln!(out, "{indent}{target}{name} = nullptr;").unwrap();
        }
        TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
            writeln!(out, "{indent}{STRING_LIST_FREE_FN}(&{target}{name});").unwrap();
        }
        TypeRef::Object { .. } => {
            writeln!(
                out,
                "{indent}nativeapi::HandleTable::GetInstance().Release({target}{name});"
            )
            .unwrap();
            writeln!(out, "{indent}{target}{name} = 0;").unwrap();
        }
        _ => {}
    }
}

fn event_field_owns(field: &Field) -> bool {
    match &field.ty {
        TypeRef::String | TypeRef::Object { .. } => true,
        TypeRef::Vector { element } => matches!(element.as_ref(), TypeRef::String),
        _ => false,
    }
}

/// Returns true if any signature uses the shared string containers.
fn header_uses_string_containers(header: &Header) -> bool {
    let is_container = |ty: &TypeRef| {
        matches!(ty, TypeRef::Map { .. })
            || matches!(ty, TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String))
    };
    header.classes.iter().any(|class| {
        class.methods.iter().any(|method| {
            is_container(&method.return_type) || method.params.iter().any(|p| is_container(&p.ty))
        }) || class
            .constructors
            .iter()
            .any(|ctor| ctor.params.iter().any(|p| is_container(&p.ty)))
    })
}
