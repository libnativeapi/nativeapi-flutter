use std::collections::{BTreeMap, BTreeSet};
use std::path::{Path, PathBuf};

use heck::{ToLowerCamelCase, ToShoutySnakeCase, ToSnakeCase, ToUpperCamelCase};

use crate::ir::{Api, Class, Constructor, Enum, Header, Method, Param, Struct, TypeRef};

/// Maps every user-defined type name to the stem of the header declaring it,
/// so generators can emit cross-header includes / imports.
pub type TypeOrigins = BTreeMap<String, String>;

pub fn type_origins(api: &Api) -> TypeOrigins {
    let mut origins = TypeOrigins::new();
    for header in &api.headers {
        for item in &header.enums {
            origins.insert(item.name.clone(), header.stem.clone());
        }
        for item in &header.structs {
            origins.insert(item.name.clone(), header.stem.clone());
        }
        for item in &header.classes {
            origins.insert(item.name.clone(), header.stem.clone());
        }
        for alias in &header.aliases {
            // Several headers re-declare the same id typedef; the first one in
            // the generation order owns it and the rest include that header.
            origins
                .entry(alias.name.clone())
                .or_insert_with(|| header.stem.clone());
        }
        for group in &header.events {
            origins.insert(group.name.clone(), header.stem.clone());
            // A listener only ever names the group, but a variant name can turn
            // up in diagnostics and in the converter, so keep both resolvable.
            for variant in &group.variants {
                origins.insert(variant.name.clone(), header.stem.clone());
            }
        }
    }
    origins
}

/// Stems of the other headers whose types this header references, in a stable
/// order.
pub fn header_dependencies(header: &Header, origins: &TypeOrigins) -> Vec<String> {
    let mut deps: Vec<String> = Vec::new();
    for name in referenced_types(header) {
        if let Some(stem) = origins.get(&name) {
            if stem != &header.stem && !deps.contains(stem) {
                deps.push(stem.clone());
            }
        }
    }
    deps.sort();
    deps
}

/// Named types this header references but does not declare itself.
pub fn foreign_types(header: &Header, origins: &TypeOrigins) -> Vec<String> {
    let mut names: Vec<String> = referenced_types(header)
        .into_iter()
        .filter(|name| origins.get(name).is_some_and(|stem| stem != &header.stem))
        .collect();
    names.sort();
    names.dedup();
    names
}

/// Every user-defined type name appearing anywhere in this header's public
/// surface, including the event payloads its emitters hand out.
fn referenced_types(header: &Header) -> Vec<String> {
    let mut names: Vec<String> = Vec::new();
    fn push(ty: &TypeRef, names: &mut Vec<String>) {
        for name in ty.named_types() {
            if !names.iter().any(|existing| existing == name) {
                names.push(name.to_string());
            }
        }
    }

    for item in &header.structs {
        for field in &item.fields {
            push(&field.ty, &mut names);
        }
        for method in &item.methods {
            push(&method.return_type, &mut names);
            for param in &method.params {
                push(&param.ty, &mut names);
            }
        }
    }
    for class in &header.classes {
        for ctor in &class.constructors {
            for param in &ctor.params {
                push(&param.ty, &mut names);
            }
        }
        for method in &class.methods {
            push(&method.return_type, &mut names);
            for param in &method.params {
                push(&param.ty, &mut names);
            }
        }
        // The listener signature names the event type, which normally lives in
        // its own header.
        if let Some(event) = &class.event {
            if !names.contains(event) {
                names.push(event.clone());
            }
        }
    }
    for group in &header.events {
        for field in group
            .common
            .iter()
            .chain(group.variants.iter().flat_map(|variant| variant.fields.iter()))
        {
            push(&field.ty, &mut names);
        }
    }
    names
}

pub fn c_params(method: &Method, class: Option<&Class>, prefix: &str) -> String {
    let mut params = Vec::new();
    if let Some(class) = class {
        if class.is_instance() && !method.is_static {
            params.push(format!(
                "{} {}",
                c_type_name(prefix, &class.name),
                c_self_param(class)
            ));
        }
    }
    let owner = class.map(|class| class.name.as_str()).unwrap_or("");
    params.extend(c_param_list(&method.params, prefix, owner, &method.name));
    if params.is_empty() {
        return "void".to_string();
    }
    params.join(", ")
}

/// Renders parameters, expanding each callback into the function pointer plus
/// its `user_data` companion.
pub fn c_param_list(
    params: &[Param],
    prefix: &str,
    owner: &str,
    member: &str,
) -> Vec<String> {
    let mut out = Vec::new();
    for param in params {
        let name = param.name.to_snake_case();
        if is_callback(&param.ty) {
            out.push(format!(
                "{} {name}",
                c_callback_type_name(prefix, owner, member)
            ));
            out.push(format!("void* {}", c_user_data_param(&param.name)));
        } else {
            out.push(format!("{} {name}", c_param_type(&param.ty, prefix)));
        }
    }
    out
}

/// A callback, with or without an `std::optional` wrapper around it.
pub fn is_callback(ty: &TypeRef) -> bool {
    matches!(ty.unwrap_optional(), TypeRef::Callback { .. })
}

/// Receiver argument name for instance methods (`Display` -> `display`).
pub fn c_self_param(class: &Class) -> String {
    class.name.to_snake_case()
}

/// Arguments for the C++ call, assuming the caller emitted the local bindings
/// that `render_param_bindings` produces for handles and containers.
pub fn c_call_args(method: &Method) -> String {
    method
        .params
        .iter()
        .map(|param| cpp_argument_expr(&param.ty, &param.name))
        .collect::<Vec<_>>()
        .join(", ")
}

/// How one parameter is spelled at the C++ call site.
pub fn cpp_argument_expr(ty: &TypeRef, name: &str) -> String {
    let name = name.to_snake_case();
    match ty {
        TypeRef::String => format!("std::string({name} ? {name} : \"\")"),
        // Resolved into a local `shared_ptr` before the call; a by-value
        // parameter dereferences it, a shared one is passed straight through.
        TypeRef::Object { shared: true, .. } => format!("{name}_cpp"),
        TypeRef::Object { .. } => format!("*{name}_cpp"),
        TypeRef::Struct { .. } => format!("{name}_cpp"),
        TypeRef::Enum { name: enum_name, .. } => format!("{}({name})", c_to_cpp_fn(enum_name)),
        TypeRef::Vector { .. } | TypeRef::Map { .. } => format!("{name}_cpp"),
        TypeRef::Optional { .. } => format!("{name}_cpp"),
        TypeRef::Callback { .. } => format!("{name}_cpp"),
        _ => name,
    }
}

pub fn c_method_symbol(prefix: &str, class: &Class, method: &Method) -> String {
    format!(
        "{}{}_{}",
        prefix,
        class.name.to_snake_case(),
        method_symbol_stem(class, method)
    )
}

/// C has no overloading, so methods sharing a name are told apart by their
/// parameters, the same way constructors are: `Run()` stays `run`, while
/// `Run(window)` becomes `run_with_window`.
pub fn method_symbol_stem(class: &Class, method: &Method) -> String {
    let base = method.name.to_snake_case();
    let overloaded = class
        .methods
        .iter()
        .filter(|other| other.name == method.name)
        .count()
        > 1;
    if !overloaded || method.params.is_empty() {
        return base;
    }
    format!(
        "{base}_with_{}",
        method
            .params
            .iter()
            .map(|param| param.name.to_snake_case())
            .collect::<Vec<_>>()
            .join("_and_")
    )
}

pub fn c_type_name(prefix: &str, name: &str) -> String {
    format!("{}{}_t", prefix, name.to_snake_case())
}

/// `Window` -> `NATIVE_INVALID_WINDOW`; the zero handle, which the handle table
/// guarantees can never refer to a live object.
pub fn c_invalid_handle_macro(prefix: &str, name: &str) -> String {
    format!(
        "{}INVALID_{}",
        prefix.to_shouty_snake_case().trim_end_matches('_').to_string() + "_",
        name.to_shouty_snake_case()
    )
}

/// `WindowEvent` -> `native_window_event_type_t`, the discriminant enum.
pub fn c_event_type_enum(prefix: &str, group: &str) -> String {
    format!("{}{}_type_t", prefix, group.to_snake_case())
}

/// `WindowEvent` + `Focused` -> `NATIVE_WINDOW_EVENT_TYPE_FOCUSED`.
pub fn c_event_variant(prefix: &str, group: &str, discriminant: &str) -> String {
    format!(
        "{}_{}_TYPE_{}",
        prefix.trim_end_matches('_').to_shouty_snake_case(),
        group.to_shouty_snake_case(),
        discriminant.to_shouty_snake_case()
    )
}

/// Field of the payload union holding this variant's extra data.
pub fn c_event_variant_field(discriminant: &str) -> String {
    discriminant.to_snake_case()
}

/// `WindowEvent` -> `native_window_event_callback_t`.
pub fn c_event_callback_type(prefix: &str, group: &str) -> String {
    format!("{}{}_callback_t", prefix, group.to_snake_case())
}

/// C++-only helper filling the C event struct from a live C++ event.
pub fn cpp_event_converter(group: &str) -> String {
    cpp_to_c_fn(group)
}

/// C++-only helper releasing whatever the converter allocated.
pub fn cpp_event_releaser(group: &str) -> String {
    format!("free_c_{}", group.to_snake_case())
}

/// C++ -> C converter for a user-defined type. Spelled like the hand-written
/// `to_c_str()` / `free_c_str()` helpers in `string_utils_c.h`, since these sit
/// in the same (global) namespace.
pub fn cpp_to_c_fn(name: &str) -> String {
    format!("to_c_{}", name.to_snake_case())
}

/// C -> C++ converter, the inverse of `cpp_to_c_fn`.
pub fn c_to_cpp_fn(name: &str) -> String {
    format!("to_cpp_{}", name.to_snake_case())
}

pub fn c_add_listener_symbol(prefix: &str, class: &str) -> String {
    format!("{}{}_add_listener", prefix, class.to_snake_case())
}

pub fn c_remove_listener_symbol(prefix: &str, class: &str) -> String {
    format!("{}{}_remove_listener", prefix, class.to_snake_case())
}

/// Name of the function-pointer typedef for a callback parameter. Callbacks are
/// named after where they are used rather than after their signature, because a
/// structural name for `void(unsigned int)` reads like line noise.
pub fn c_callback_type_name(prefix: &str, owner: &str, member: &str) -> String {
    let member = member.to_snake_case();
    // `SetCallback` would otherwise yield `..._set_callback_callback_t`.
    let member = member.strip_suffix("_callback").unwrap_or(&member);
    let member = if member == "callback" { "" } else { member };
    if member.is_empty() {
        return format!("{}{}_callback_t", prefix, owner.to_snake_case());
    }
    format!("{}{}_{member}_callback_t", prefix, owner.to_snake_case())
}

/// The `user_data` companion of a callback parameter.
pub fn c_user_data_param(name: &str) -> String {
    format!("{}_user_data", name.to_snake_case())
}

pub fn c_free_symbol(prefix: &str, name: &str) -> String {
    format!("{}{}_free", prefix, name.to_snake_case())
}

/// `Display` -> `native_display_list_t`
pub fn c_list_type_name(prefix: &str, name: &str) -> String {
    format!("{}{}_list_t", prefix, name.to_snake_case())
}

/// Field holding the elements of a generated list struct (`displays`).
pub fn c_list_field(name: &str) -> String {
    pluralize(&name.to_snake_case())
}

/// Frees the array *and* every handle it holds.
pub fn c_list_free_symbol(prefix: &str, name: &str) -> String {
    format!("{}{}_list_free", prefix, name.to_snake_case())
}

/// Frees only the array; the caller keeps ownership of the handles.
pub fn c_list_release_symbol(prefix: &str, name: &str) -> String {
    format!("{}{}_list_release", prefix, name.to_snake_case())
}

/// `Preferences()` -> `native_preferences_create`;
/// `Preferences(scope)` -> `native_preferences_create_with_scope`.
pub fn c_constructor_symbol(prefix: &str, class: &Class, ctor: &Constructor) -> String {
    let base = format!("{}{}_create", prefix, class.name.to_snake_case());
    match constructor_suffix(class, ctor) {
        Some(suffix) => format!("{base}_{}", suffix.to_snake_case()),
        None => base,
    }
}

/// A lone constructor needs no disambiguation, so it keeps the bare `_create`
/// name; only genuine overloads carry the parameter suffix.
pub fn constructor_suffix(class: &Class, ctor: &Constructor) -> Option<String> {
    if class.constructors.len() < 2 {
        return None;
    }
    ctor.overload_suffix()
}

/// Binding-side constructor name: `new` for the default constructor,
/// `with_scope` for overloads.
pub fn rust_constructor_name(class: &Class, ctor: &Constructor) -> String {
    match constructor_suffix(class, ctor) {
        Some(suffix) => suffix.to_snake_case(),
        None => "new".to_string(),
    }
}

pub fn c_native_object_symbol(prefix: &str, name: &str) -> String {
    format!("{}{}_get_native_object", prefix, name.to_snake_case())
}

/// Repo-wide string helpers shared by every generated translation unit.
pub const STRING_UTILS_HEADER: &str = "string_utils_c.h";

/// Generated header holding the definitions no C++ header owns.
pub const COMMON_HEADER: &str = "common_c.h";


pub const LISTENER_ID_TYPE: &str = "native_listener_id_t";

/// C++ helper that copies a `std::string` into a C string owned by the caller.
pub const STRING_DUP_FN: &str = "to_c_str";

/// Frees a string returned by any generated C function.
pub const STRING_FREE_FN: &str = "free_c_str";

/// Value containers of strings, also provided by `string_utils_c.h`.
pub const STRING_LIST_TYPE: &str = "native_string_list_t";
pub const STRING_LIST_DUP_FN: &str = "to_c_string_list";
pub const STRING_LIST_FREE_FN: &str = "native_string_list_free";
pub const STRING_MAP_TYPE: &str = "native_string_map_t";
pub const STRING_MAP_DUP_FN: &str = "to_c_string_map";
pub const STRING_MAP_FREE_FN: &str = "native_string_map_free";

fn pluralize(name: &str) -> String {
    if name.ends_with('s') {
        // Already plural (`preferences`); doubling it reads as a typo.
        name.to_string()
    } else if name.ends_with('y') && !name.ends_with("ay") && !name.ends_with("ey") {
        format!("{}ies", &name[..name.len() - 1])
    } else if name.ends_with('x') || name.ends_with("ch") || name.ends_with("sh") {
        format!("{name}es")
    } else {
        format!("{name}s")
    }
}

/// Class names that some method returns as a `std::vector<T>`; only those need
/// a generated list type.
pub fn listed_classes(api: &Api) -> BTreeSet<String> {
    let mut names = BTreeSet::new();
    for header in &api.headers {
        for class in &header.classes {
            for method in &class.methods {
                if let TypeRef::Vector { element } = &method.return_type {
                    if let TypeRef::Object { name, .. } = element.as_ref() {
                        names.insert(name.clone());
                    }
                }
            }
        }
    }
    names
}

/// Accessors are only reshaped for instance classes; singleton entry points
/// keep their C++ spelling so `UrlOpener.isSupported()` stays a function.
pub fn is_binding_accessor(class: &Class, method: &Method) -> bool {
    class.is_instance() && !method.is_static && method.is_accessor()
}

fn binding_name<'a>(class: &Class, method: &'a Method) -> &'a str {
    if is_binding_accessor(class, method) {
        method.binding_name()
    } else {
        &method.name
    }
}

/// Binding-side method name: `GetWorkArea` -> `work_area`, `Open` -> `open`.
///
/// Overloads get the same parameter suffix the C symbol does — Rust has no
/// overloading either — and Rust keywords are escaped.
pub fn rust_method_name(class: &Class, method: &Method) -> String {
    rust_ident(&with_overload_suffix(
        binding_name(class, method).to_snake_case(),
        class,
        method,
    ))
}

/// Binding-side method name: `GetWorkArea` -> `workArea`, `Open` -> `open`.
///
/// Swift does have overloading, but only when the argument labels differ; two
/// zero-argument overloads or two that differ solely by type would still clash,
/// so the same suffix rule applies.
pub fn swift_method_name(class: &Class, method: &Method) -> String {
    with_overload_suffix(
        binding_name(class, method).to_lower_camel_case(),
        class,
        method,
    )
    .to_lower_camel_case()
}

fn with_overload_suffix(base: String, class: &Class, method: &Method) -> String {
    let overloaded = class
        .methods
        .iter()
        .filter(|other| other.name == method.name)
        .count()
        > 1;
    if !overloaded || method.params.is_empty() {
        return base;
    }
    format!(
        "{base}_with_{}",
        method
            .params
            .iter()
            .map(|param| param.name.to_snake_case())
            .collect::<Vec<_>>()
            .join("_and_")
    )
}

/// Rust keywords that turn up as C++ member names (`GetType` -> `type`).
const RUST_KEYWORDS: &[&str] = &[
    "as", "break", "const", "continue", "crate", "else", "enum", "extern", "false", "fn", "for",
    "if", "impl", "in", "let", "loop", "match", "mod", "move", "mut", "pub", "ref", "return",
    "self", "static", "struct", "super", "trait", "true", "type", "unsafe", "use", "where",
    "while", "async", "await", "dyn", "abstract", "become", "box", "do", "final", "macro",
    "override", "priv", "typeof", "unsized", "virtual", "yield", "try",
];

pub fn rust_ident(name: &str) -> String {
    if RUST_KEYWORDS.contains(&name) {
        format!("r#{name}")
    } else {
        name.to_string()
    }
}

pub fn c_enum_variant(prefix: &str, item: &Enum, variant: &str) -> String {
    let stripped = variant.strip_prefix('k').unwrap_or(variant);
    format!(
        "{}_{}_{}",
        prefix.trim_end_matches('_').to_shouty_snake_case(),
        item.name.to_shouty_snake_case(),
        stripped.to_shouty_snake_case()
    )
}

pub fn rust_enum_variant(name: &str) -> String {
    name.strip_prefix('k').unwrap_or(name).to_upper_camel_case()
}

pub fn c_return_type(ty: &TypeRef, prefix: &str) -> String {
    match ty {
        TypeRef::Void => "void".to_string(),
        _ => c_field_type(ty, prefix),
    }
}

pub fn c_param_type(ty: &TypeRef, prefix: &str) -> String {
    match ty {
        TypeRef::String => "const char*".to_string(),
        // A struct has no spare null state, so an optional one becomes a
        // nullable pointer; everything else already allows null.
        TypeRef::Optional { inner } => match inner.as_ref() {
            TypeRef::Struct { name, .. } => format!("const {}*", c_type_name(prefix, name)),
            other => c_param_type(other, prefix),
        },
        _ => c_field_type(ty, prefix),
    }
}

pub fn c_field_type(ty: &TypeRef, prefix: &str) -> String {
    match ty {
        TypeRef::Void => "void".to_string(),
        TypeRef::Bool => "bool".to_string(),
        TypeRef::Int { name } => c_int_type(name),
        TypeRef::Float { name } => c_float_type(name),
        TypeRef::String => "char*".to_string(),
        TypeRef::CString => "const char*".to_string(),
        TypeRef::Alias { name, .. } => c_type_name(prefix, name),
        TypeRef::Enum { name, .. } | TypeRef::Struct { name, .. } | TypeRef::Object { name, .. } => {
            c_type_name(prefix, name)
        }
        TypeRef::Vector { element } => match element.as_ref() {
            TypeRef::Object { name, .. } => c_list_type_name(prefix, name),
            TypeRef::String => STRING_LIST_TYPE.to_string(),
            other => c_field_type(other, prefix),
        },
        TypeRef::Map { .. } => STRING_MAP_TYPE.to_string(),
        // Absence is the null pointer / invalid handle the payload already has
        // room for, so an optional needs no extra flag.
        TypeRef::Optional { inner } => c_field_type(inner, prefix),
        TypeRef::Callback { .. } | TypeRef::RawPointer | TypeRef::Unsupported { .. } => {
            "void*".to_string()
        }
    }
}

pub fn c_float_type(name: &str) -> String {
    match name {
        "float" => "float".to_string(),
        "double" => "double".to_string(),
        "long double" => "long double".to_string(),
        _ => name.to_string(),
    }
}

pub fn c_int_type(name: &str) -> String {
    match name {
        "unsigned char" => "unsigned char".to_string(),
        "unsigned short" => "unsigned short".to_string(),
        "unsigned int" => "unsigned int".to_string(),
        "unsigned long" => "unsigned long".to_string(),
        "unsigned long long" => "unsigned long long".to_string(),
        _ => name.to_string(),
    }
}

pub fn rust_public_type(ty: &TypeRef) -> String {
    match ty {
        TypeRef::Void => "()".to_string(),
        TypeRef::Bool => "bool".to_string(),
        TypeRef::Int { name } => rust_int_type(name),
        TypeRef::Float { name } => rust_float_type(name),
        TypeRef::String | TypeRef::CString => "Option<String>".to_string(),
        // A named integer alias keeps its name; it is a `pub type` on the Rust
        // side too, so `WindowId` stays `WindowId` rather than decaying to u32.
        TypeRef::Alias { name, .. } => name.clone(),
        TypeRef::Enum { name, .. } | TypeRef::Struct { name, .. } => name.clone(),
        // Handles can always be null on the C side.
        TypeRef::Object { name, .. } => format!("Option<{name}>"),
        TypeRef::Vector { element } => format!("Vec<{}>", rust_element_type(element)),
        TypeRef::Map { .. } => "std::collections::HashMap<String, String>".to_string(),
        TypeRef::Optional { inner } => match inner.as_ref() {
            TypeRef::String => "Option<String>".to_string(),
            other => rust_public_type(other),
        },
        TypeRef::Callback { .. } => "()".to_string(),
        TypeRef::RawPointer => "*mut std::ffi::c_void".to_string(),
        TypeRef::Unsupported { name } => format!("/* unsupported: {name} */ ()"),
    }
}

fn rust_element_type(ty: &TypeRef) -> String {
    match ty {
        TypeRef::Object { name, .. } => name.clone(),
        TypeRef::String => "String".to_string(),
        other => rust_public_type(other),
    }
}

pub fn rust_float_type(name: &str) -> String {
    match name {
        "float" => "f32",
        "double" | "long double" => "f64",
        _ => "f64",
    }
    .to_string()
}

pub fn rust_int_type(name: &str) -> String {
    // `long` is 32-bit on Windows and 64-bit elsewhere, so keep the C alias
    // instead of committing to a fixed width.
    match name {
        "char" | "signed char" => "i8",
        "short" => "i16",
        "int" => "i32",
        "long" => "std::os::raw::c_long",
        "long long" => "i64",
        "unsigned char" => "u8",
        "unsigned short" => "u16",
        "unsigned int" => "u32",
        "unsigned long" => "std::os::raw::c_ulong",
        "unsigned long long" => "u64",
        _ => "i32",
    }
    .to_string()
}

pub fn struct_has_owned_fields(item: &Struct) -> bool {
    item.fields
        .iter()
        .any(|field| matches!(field.ty, TypeRef::String))
}

pub fn relative_include(from_dir: &Path, target: &Path) -> String {
    lexical_relative_path(from_dir, target)
        .to_string_lossy()
        .replace('\\', "/")
}

pub fn lexical_relative_path(from_dir: &Path, target: &Path) -> PathBuf {
    let from = lexical_components(from_dir);
    let to = lexical_components(target);
    let common = from
        .iter()
        .zip(to.iter())
        .take_while(|(left, right)| left == right)
        .count();

    let mut result = PathBuf::new();
    for _ in common..from.len() {
        result.push("..");
    }
    for component in &to[common..] {
        result.push(component);
    }
    result
}

pub fn lexical_components(path: &Path) -> Vec<String> {
    let mut parts = Vec::new();
    for component in path.components() {
        match component {
            std::path::Component::Normal(value) => {
                parts.push(value.to_string_lossy().to_string());
            }
            std::path::Component::ParentDir => {
                parts.pop();
            }
            _ => {}
        }
    }
    parts
}

#[cfg(test)]
mod tests {
    use super::{
        c_callback_type_name, c_enum_variant, c_event_callback_type, c_event_type_enum,
        c_event_variant, c_invalid_handle_macro, c_list_field, c_list_type_name, c_method_symbol,
        rust_method_name, swift_method_name,
    };
    use crate::ir::{Class, ClassKind, Enum, Method, Param, TypeRef};

    fn method(name: &str, is_const: bool) -> Method {
        Method {
            name: name.to_string(),
            return_type: TypeRef::Bool,
            params: vec![],
            is_const,
            is_static: false,
        }
    }

    fn class(name: &str, kind: ClassKind) -> Class {
        Class {
            name: name.to_string(),
            qualified_name: format!("nativeapi::{name}"),
            kind,
            native_object: false,
            constructors: vec![],
            methods: vec![],
            event: None,
        }
    }

    #[test]
    fn creates_c_method_symbols() {
        assert_eq!(
            c_method_symbol(
                "native_",
                &class("UrlOpener", ClassKind::Singleton),
                &method("IsSupported", true)
            ),
            "native_url_opener_is_supported"
        );
    }

    #[test]
    fn strips_get_prefix_for_instance_accessors_only() {
        let display = class("Display", ClassKind::Instance);
        assert_eq!(
            rust_method_name(&display, &method("GetWorkArea", true)),
            "work_area"
        );
        assert_eq!(
            swift_method_name(&display, &method("GetWorkArea", true)),
            "workArea"
        );
        assert_eq!(
            swift_method_name(&display, &method("IsPrimary", true)),
            "isPrimary"
        );

        // Non-const methods and singleton entry points keep their C++ spelling.
        assert_eq!(
            rust_method_name(&display, &method("GetAll", false)),
            "get_all"
        );
        let manager = class("DisplayManager", ClassKind::Singleton);
        assert_eq!(
            rust_method_name(&manager, &method("GetPrimary", true)),
            "get_primary"
        );
    }

    #[test]
    fn creates_list_names() {
        assert_eq!(c_list_type_name("native_", "Display"), "native_display_list_t");
        assert_eq!(c_list_field("Display"), "displays");
        // Already-plural class names are left alone.
        assert_eq!(c_list_field("Preferences"), "preferences");
    }

    #[test]
    fn disambiguates_overloaded_methods_by_parameters() {
        let mut application = class("Application", ClassKind::Singleton);
        let run = Method {
            name: "Run".to_string(),
            return_type: TypeRef::Int {
                name: "int".to_string(),
            },
            params: vec![],
            is_const: false,
            is_static: false,
        };
        let run_with_window = Method {
            params: vec![Param {
                name: "window".to_string(),
                ty: TypeRef::Object {
                    name: "Window".to_string(),
                    qualified_name: "nativeapi::Window".to_string(),
                    shared: true,
                },
            }],
            ..run.clone()
        };
        application.methods = vec![run.clone(), run_with_window.clone()];

        // The nullary overload keeps the plain name so the common call stays short.
        assert_eq!(
            c_method_symbol("native_", &application, &run),
            "native_application_run"
        );
        assert_eq!(
            c_method_symbol("native_", &application, &run_with_window),
            "native_application_run_with_window"
        );

        // With only one Run, no suffix appears at all.
        application.methods = vec![run_with_window.clone()];
        assert_eq!(
            c_method_symbol("native_", &application, &run_with_window),
            "native_application_run"
        );
    }

    #[test]
    fn names_callback_typedefs_without_stutter() {
        assert_eq!(
            c_callback_type_name("native_", "Shortcut", "SetCallback"),
            "native_shortcut_set_callback_t"
        );
        assert_eq!(
            c_callback_type_name("native_", "ShortcutOptions", "callback"),
            "native_shortcut_options_callback_t"
        );
        assert_eq!(
            c_callback_type_name("native_", "WindowManager", "SetWillShowHook"),
            "native_window_manager_set_will_show_hook_callback_t"
        );
    }

    #[test]
    fn creates_handle_sentinels_and_event_names() {
        assert_eq!(
            c_invalid_handle_macro("native_", "TrayIcon"),
            "NATIVE_INVALID_TRAY_ICON"
        );
        assert_eq!(
            c_event_type_enum("native_", "WindowEvent"),
            "native_window_event_type_t"
        );
        assert_eq!(
            c_event_variant("native_", "WindowEvent", "Focused"),
            "NATIVE_WINDOW_EVENT_TYPE_FOCUSED"
        );
        assert_eq!(
            c_event_callback_type("native_", "MenuEvent"),
            "native_menu_event_callback_t"
        );
    }

    #[test]
    fn creates_c_enum_variants() {
        let item = Enum {
            name: "UrlOpenErrorCode".to_string(),
            qualified_name: "nativeapi::UrlOpenErrorCode".to_string(),
            variants: vec![],
        };
        assert_eq!(
            c_enum_variant("native_", &item, "kInvalidUrlEmpty"),
            "NATIVE_URL_OPEN_ERROR_CODE_INVALID_URL_EMPTY"
        );
    }
}
