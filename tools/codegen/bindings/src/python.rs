//! Python bindings: `ctypes` over the C ABI, no compiled glue.
//!
//! Two layers, both generated from the IR:
//!
//! - `nativeapi/_capi.py` mirrors the C ABI one to one: a `ctypes` structure
//!   per C struct, a `CFUNCTYPE` per callback signature and a typed foreign
//!   function per symbol.
//! - `nativeapi/<stem>.py` is the public API of one header: `IntEnum`s,
//!   dataclasses for value types and events, and classes wrapping handles.
//!
//! The hand-written `_library.py` (loading the shared library) and
//! `_runtime.py` (handle ownership, string marshalling, callbacks, the event
//! loop) are what both layers import.

use std::collections::{BTreeMap, BTreeSet};
use std::fmt::Write;
use std::path::Path;

use heck::{ToShoutySnakeCase, ToSnakeCase};

use codegen_shared::ir::{
    Api, Class, ClassKind, Constructor, Enum, EventGroup, Field, Header, Method, Param, Struct,
    TypeRef,
};
use codegen_shared::naming::{
    c_add_listener_symbol, c_constructor_symbol, c_free_symbol, c_list_field, c_list_free_symbol,
    c_list_release_symbol, c_list_type_name, c_method_symbol, c_native_object_symbol,
    c_release_user_data_param, c_remove_listener_symbol, c_type_name, c_user_data_param,
    constructor_suffix, is_binding_accessor, listed_classes, struct_has_owned_fields, TypeOrigins,
    RELEASE_USER_DATA_TYPE, STRING_FREE_FN, STRING_LIST_FREE_FN, STRING_LIST_TYPE,
    STRING_MAP_FREE_FN, STRING_MAP_TYPE,
};
use codegen_shared::GeneratedFile;

const BANNER: &str = "# AUTO-GENERATED. DO NOT EDIT.\n# Any manual changes WILL BE LOST when this file is regenerated.\n";

/// The `Application` loop entry points, rerouted through `_runtime.py`.
const LOOP_RUN: &str = "native_application_run";
const LOOP_RUN_WITH_WINDOW: &str = "native_application_run_with_window";
const LOOP_QUIT: &str = "native_application_quit";

/// `<stem>.py` for one header.
pub fn generate(
    api: &Api,
    header: &Header,
    origins: &TypeOrigins,
    package: &Path,
    prefix: &str,
) -> GeneratedFile {
    GeneratedFile {
        path: package.join(format!("{}.py", header.stem)),
        contents: public_module(api, header, origins, prefix),
    }
}

/// `_capi.py` (the raw layer) and `__init__.py` (the re-exports).
pub fn generate_shared(api: &Api, package: &Path, prefix: &str) -> Vec<GeneratedFile> {
    vec![
        GeneratedFile {
            path: package.join("_capi.py"),
            contents: capi_module(api, prefix),
        },
        GeneratedFile {
            path: package.join("__init__.py"),
            contents: init_module(api),
        },
    ]
}

// ---------------------------------------------------------------------------
// __init__.py
// ---------------------------------------------------------------------------

/// Names hand-written in `_runtime.py` that belong to the public API.
const RUNTIME_EXPORTS: &[&str] = &["NativeApiError", "NativeObject", "is_event_loop_running"];

fn init_module(api: &Api) -> String {
    let mut out = String::from(BANNER);
    writeln!(
        out,
        "\"\"\"Native desktop APIs (windows, tray icons, menus, displays, shortcuts,\ndialogs, storage) for Python, over the libnativeapi C ABI.\"\"\"\n"
    )
    .unwrap();
    // Module -> names, sorted the way isort sorts them.
    let mut modules: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    modules.insert(
        "_runtime".to_string(),
        RUNTIME_EXPORTS
            .iter()
            .map(|name| name.to_string())
            .collect(),
    );
    let mut seen: BTreeSet<String> = RUNTIME_EXPORTS
        .iter()
        .map(|name| name.to_string())
        .collect();
    for header in &api.headers {
        for name in public_names(header) {
            if seen.insert(name.clone()) {
                modules.entry(header.stem.clone()).or_default().insert(name);
            }
        }
    }
    for (module, names) in &modules {
        writeln!(out, "from .{module} import (").unwrap();
        let mut names: Vec<&String> = names.iter().collect();
        // isort's order-by-type: constants, then classes, then the rest.
        names.sort_by_key(|name| {
            let kind = if name.chars().all(|c| !c.is_lowercase()) {
                0
            } else if name.starts_with(char::is_uppercase) {
                1
            } else {
                2
            };
            (kind, name.to_lowercase(), name.to_string())
        });
        for name in names {
            writeln!(out, "    {name},").unwrap();
        }
        writeln!(out, ")").unwrap();
    }
    let all: BTreeSet<&String> = modules.values().flatten().collect();
    writeln!(out).unwrap();
    writeln!(out, "__all__ = [").unwrap();
    for name in &all {
        writeln!(out, "    \"{name}\",").unwrap();
    }
    writeln!(out, "]").unwrap();
    out
}

/// Every top-level name a header module defines, in definition order.
fn public_names(header: &Header) -> Vec<String> {
    let mut names = Vec::new();
    let mut seen = BTreeSet::new();
    for alias in &header.aliases {
        if seen.insert(alias.name.clone()) {
            names.push(alias.name.clone());
        }
    }
    names.extend(header.enums.iter().map(|item| item.name.clone()));
    names.extend(header.structs.iter().map(|item| item.name.clone()));
    for group in &header.events {
        names.push(group.name.clone());
        names.extend(group.variants.iter().map(|variant| variant.name.clone()));
    }
    names.extend(header.classes.iter().map(|class| class.name.clone()));
    names
}

// ---------------------------------------------------------------------------
// _capi.py: the raw layer
// ---------------------------------------------------------------------------

/// One `ctypes` aggregate, declared up front and completed in dependency
/// order: a structure can only take its `_fields_` once every structure it
/// embeds by value has its own.
struct RawAggregate {
    name: String,
    union: bool,
    fields: Vec<(String, String)>,
}

impl RawAggregate {
    fn deps(&self) -> impl Iterator<Item = &str> {
        self.fields.iter().map(|(_, ty)| ty.as_str())
    }
}

/// Callback signatures by their `CFUNCTYPE` name.
type Callbacks = BTreeMap<String, String>;

fn capi_module(api: &Api, prefix: &str) -> String {
    let mut aggregates: Vec<RawAggregate> = Vec::new();
    let mut callbacks = Callbacks::new();
    callbacks.insert(
        RELEASE_USER_DATA_TYPE.to_string(),
        "CFUNCTYPE(None, c_void_p)".to_string(),
    );

    for header in &api.headers {
        for item in &header.structs {
            let mut fields = Vec::new();
            for field in &item.fields {
                let name = raw_field_name(&field.name);
                match field.ty.unwrap_optional() {
                    TypeRef::Callback { params } => {
                        fields.push((name, callback_type(&mut callbacks, params, prefix)));
                        fields.push((c_user_data_param(&field.name), "c_void_p".to_string()));
                        fields.push((
                            c_release_user_data_param(&field.name),
                            RELEASE_USER_DATA_TYPE.to_string(),
                        ));
                    }
                    other => fields.push((name, raw_type(other, prefix))),
                }
            }
            aggregates.push(RawAggregate {
                name: c_type_name(prefix, &item.name),
                union: false,
                fields,
            });
        }
        for group in &header.events {
            event_aggregates(&mut aggregates, group, prefix);
        }
    }
    for class in listed_classes(api) {
        aggregates.push(RawAggregate {
            name: c_list_type_name(prefix, &class),
            union: false,
            fields: vec![
                (c_list_field(&class), "POINTER(c_uint64)".to_string()),
                ("count".to_string(), "c_long".to_string()),
            ],
        });
    }

    let mut out = String::from(BANNER);
    writeln!(
        out,
        "\"\"\"The C ABI as ctypes declarations, one to one. Application code should use\nthe public modules instead.\"\"\"\n"
    )
    .unwrap();
    let out_header = out;
    let mut out = String::new();

    writeln!(out, "# --- string containers (string_utils_c.h) ---\n\n").unwrap();
    writeln!(
        out,
        "class {STRING_LIST_TYPE}(Structure):\n    _fields_ = [(\"items\", POINTER(c_char_p)), (\"count\", c_long)]\n\n"
    )
    .unwrap();
    writeln!(
        out,
        "class {STRING_MAP_TYPE}(Structure):\n    _fields_ = [\n        (\"keys\", POINTER(c_char_p)),\n        (\"values\", POINTER(c_char_p)),\n        (\"count\", c_long),\n    ]\n\n"
    )
    .unwrap();
    for (symbol, arg) in [
        (STRING_FREE_FN, "c_void_p".to_string()),
        (STRING_LIST_FREE_FN, format!("POINTER({STRING_LIST_TYPE})")),
        (STRING_MAP_FREE_FN, format!("POINTER({STRING_MAP_TYPE})")),
    ] {
        writeln!(out, "{}", function_decl(symbol, "None", &[arg])).unwrap();
    }
    writeln!(out).unwrap();

    writeln!(out, "# --- structures ---\n\n").unwrap();
    for aggregate in &aggregates {
        let base = if aggregate.union {
            "Union"
        } else {
            "Structure"
        };
        writeln!(out, "class {}({base}):\n    pass\n\n", aggregate.name).unwrap();
    }

    // Functions are rendered first so every callback signature they mention
    // is known before the callback section is written.
    let mut functions = String::new();
    for header in &api.headers {
        render_header_functions(&mut functions, api, header, &mut callbacks, prefix);
    }

    writeln!(out, "# --- callbacks ---\n").unwrap();
    for (name, signature) in &callbacks {
        let line = format!("{name} = {signature}");
        match signature.strip_prefix("CFUNCTYPE(") {
            Some(args) if line.len() > 88 => {
                writeln!(out, "{name} = CFUNCTYPE(").unwrap();
                for arg in split_args(args.strip_suffix(')').unwrap_or(args)) {
                    writeln!(out, "    {arg},").unwrap();
                }
                writeln!(out, ")").unwrap();
            }
            _ => writeln!(out, "{line}").unwrap(),
        }
    }
    writeln!(out).unwrap();

    writeln!(out, "# --- structure layouts, in dependency order ---\n").unwrap();
    let names: BTreeSet<&str> = aggregates.iter().map(|item| item.name.as_str()).collect();
    let mut done: BTreeSet<String> = BTreeSet::new();
    for aggregate in &aggregates {
        emit_fields(&mut out, aggregate, &aggregates, &names, &mut done);
    }
    writeln!(out).unwrap();

    let constants: Vec<(String, String)> = api
        .headers
        .iter()
        .flat_map(|header| header.structs.iter())
        .flat_map(|item| {
            item.constants.iter().map(move |constant| {
                (
                    c_struct_constant(prefix, &item.name, constant),
                    c_type_name(prefix, &item.name),
                )
            })
        })
        .collect();
    if !constants.is_empty() {
        writeln!(out, "# --- constants ---\n").unwrap();
        for (symbol, ty) in constants {
            writeln!(out, "{symbol} = constant(\"{symbol}\", {ty})").unwrap();
        }
        writeln!(out).unwrap();
    }

    writeln!(out, "# --- functions ---").unwrap();
    out.push_str(&functions);

    let mut result = out_header;
    writeln!(result, "from ctypes import (").unwrap();
    for name in CTYPES_NAMES {
        if uses_ident(&out, name) {
            writeln!(result, "    {name},").unwrap();
        }
    }
    writeln!(result, ")\n\nfrom ._library import constant, function\n").unwrap();
    result.push_str(&out);
    result
}

/// Everything `_capi.py` may import from `ctypes`, in import order.
const CTYPES_NAMES: &[&str] = &[
    "CFUNCTYPE",
    "POINTER",
    "Structure",
    "Union",
    "c_bool",
    "c_byte",
    "c_char_p",
    "c_double",
    "c_float",
    "c_int",
    "c_long",
    "c_longlong",
    "c_short",
    "c_ubyte",
    "c_uint",
    "c_uint64",
    "c_ulong",
    "c_ushort",
    "c_void_p",
];

/// Whether `ident` occurs in `text` as a whole identifier.
fn uses_ident(text: &str, ident: &str) -> bool {
    let is_ident = |c: char| c.is_ascii_alphanumeric() || c == '_';
    text.match_indices(ident).any(|(start, _)| {
        let before = text[..start].chars().next_back();
        let after = text[start + ident.len()..].chars().next();
        !before.is_some_and(is_ident) && !after.is_some_and(is_ident)
    })
}

fn emit_fields(
    out: &mut String,
    aggregate: &RawAggregate,
    all: &[RawAggregate],
    names: &BTreeSet<&str>,
    done: &mut BTreeSet<String>,
) {
    if !done.insert(aggregate.name.clone()) {
        return;
    }
    for dep in aggregate.deps() {
        if names.contains(dep) {
            if let Some(inner) = all.iter().find(|item| item.name == dep) {
                emit_fields(out, inner, all, names, done);
            }
        }
    }
    if aggregate.fields.is_empty() {
        writeln!(out, "{}._fields_ = []", aggregate.name).unwrap();
        return;
    }
    writeln!(out, "{}._fields_ = [", aggregate.name).unwrap();
    for (name, ty) in &aggregate.fields {
        writeln!(out, "    (\"{name}\", {ty}),").unwrap();
    }
    writeln!(out, "]").unwrap();
}

/// The tagged event struct: `type`, the common fields, then a union of the
/// variant payloads.
fn event_aggregates(aggregates: &mut Vec<RawAggregate>, group: &EventGroup, prefix: &str) {
    let event_ty = c_type_name(prefix, &group.name);
    let union_ty = event_union_type(prefix, group);
    let mut union_fields = Vec::new();
    for variant in group
        .variants
        .iter()
        .filter(|variant| !variant.fields.is_empty())
    {
        let payload_ty = event_payload_type(prefix, group, &variant.discriminant);
        aggregates.push(RawAggregate {
            name: payload_ty.clone(),
            union: false,
            fields: variant
                .fields
                .iter()
                .map(|field| {
                    (
                        raw_field_name(&field.name),
                        raw_type(field.ty.unwrap_optional(), prefix),
                    )
                })
                .collect(),
        });
        union_fields.push((event_payload_field(&variant.discriminant), payload_ty));
    }
    let mut fields = vec![("type".to_string(), "c_int".to_string())];
    fields.extend(group.common.iter().map(|field| {
        (
            raw_field_name(&field.name),
            raw_type(field.ty.unwrap_optional(), prefix),
        )
    }));
    if !union_fields.is_empty() {
        aggregates.push(RawAggregate {
            name: union_ty.clone(),
            union: true,
            fields: union_fields,
        });
        fields.push(("data".to_string(), union_ty));
    }
    aggregates.push(RawAggregate {
        name: event_ty,
        union: false,
        fields,
    });
}

fn event_union_type(prefix: &str, group: &EventGroup) -> String {
    format!("{}{}_data_t", prefix, group.name.to_snake_case())
}

fn event_payload_type(prefix: &str, group: &EventGroup, discriminant: &str) -> String {
    format!(
        "{}{}_{}_t",
        prefix,
        group.name.to_snake_case(),
        discriminant.to_snake_case()
    )
}

fn event_payload_field(discriminant: &str) -> String {
    codegen_shared::naming::c_event_variant_field(discriminant)
}

fn event_callback_type(prefix: &str, group: &str) -> String {
    codegen_shared::naming::c_event_callback_type(prefix, group)
}

fn render_header_functions(
    out: &mut String,
    api: &Api,
    header: &Header,
    callbacks: &mut Callbacks,
    prefix: &str,
) {
    let mut lines: Vec<String> = Vec::new();
    let listed = listed_classes(api);

    for item in &header.structs {
        let c_ty = c_type_name(prefix, &item.name);
        if struct_has_owned_fields(item) {
            let free = c_free_symbol(prefix, &item.name);
            lines.push(function_decl(&free, "None", &[format!("POINTER({c_ty})")]));
        }
        for method in &item.methods {
            let mut args = Vec::new();
            if !method.is_static {
                args.push(c_ty.clone());
            }
            args.extend(param_ctypes(&method.params, callbacks, prefix));
            lines.push(function_decl(
                &c_struct_method_symbol(prefix, item, method),
                &return_ctype(&method.return_type, prefix),
                &args,
            ));
        }
    }

    for group in &header.events {
        let event_ty = c_type_name(prefix, &group.name);
        callbacks.insert(
            event_callback_type(prefix, &group.name),
            format!("CFUNCTYPE(None, POINTER({event_ty}), c_void_p)"),
        );
    }

    for class in &header.classes {
        if listed.contains(&class.name) {
            let list_ty = c_list_type_name(prefix, &class.name);
            for symbol in [
                c_list_free_symbol(prefix, &class.name),
                c_list_release_symbol(prefix, &class.name),
            ] {
                lines.push(function_decl(
                    &symbol,
                    "None",
                    &[format!("POINTER({list_ty})")],
                ));
            }
        }
        if class.is_instance() {
            lines.push(function_decl(
                &c_free_symbol(prefix, &class.name),
                "None",
                &["c_uint64".to_string()],
            ));
            if class.native_object {
                lines.push(function_decl(
                    &c_native_object_symbol(prefix, &class.name),
                    "c_void_p",
                    &["c_uint64".to_string()],
                ));
            }
        }
        for ctor in &class.constructors {
            lines.push(function_decl(
                &c_constructor_symbol(prefix, class, ctor),
                "c_uint64",
                &param_ctypes(&ctor.params, callbacks, prefix),
            ));
        }
        for method in &class.methods {
            let mut args = Vec::new();
            if class.is_instance() && !method.is_static {
                args.push("c_uint64".to_string());
            }
            args.extend(param_ctypes(&method.params, callbacks, prefix));
            lines.push(function_decl(
                &c_method_symbol(prefix, class, method),
                &return_ctype(&method.return_type, prefix),
                &args,
            ));
        }
        if let Some(group) = emitted_group(api, class) {
            let receiver: Vec<String> = if class.is_instance() {
                vec!["c_uint64".to_string()]
            } else {
                Vec::new()
            };
            let mut add_args = receiver.clone();
            add_args.push(event_callback_type(prefix, &group.name));
            add_args.push("c_void_p".to_string());
            add_args.push(RELEASE_USER_DATA_TYPE.to_string());
            lines.push(function_decl(
                &c_add_listener_symbol(prefix, &class.name),
                "c_uint64",
                &add_args,
            ));
            let mut remove_args = receiver;
            remove_args.push("c_uint64".to_string());
            lines.push(function_decl(
                &c_remove_listener_symbol(prefix, &class.name),
                "c_bool",
                &remove_args,
            ));
        }
    }

    if lines.is_empty() {
        return;
    }
    let path = header.path.to_string_lossy();
    let name = path.rsplit("/src/").next().unwrap_or(&path);
    writeln!(out, "\n# {name}\n").unwrap();
    for line in lines {
        writeln!(out, "{line}").unwrap();
    }
}

fn function_decl(symbol: &str, restype: &str, args: &[String]) -> String {
    let one_line = format!(
        "{symbol} = function(\"{symbol}\", {restype}, [{}])",
        args.join(", ")
    );
    if one_line.len() <= 88 {
        return one_line;
    }
    let mut out = format!("{symbol} = function(\n    \"{symbol}\",\n    {restype},\n    [\n");
    for arg in args {
        writeln!(out, "        {arg},").unwrap();
    }
    out.push_str("    ],\n)");
    out
}

fn param_ctypes(params: &[Param], callbacks: &mut Callbacks, prefix: &str) -> Vec<String> {
    let mut out = Vec::new();
    for param in params {
        match &param.ty {
            TypeRef::String | TypeRef::CString => out.push("c_char_p".to_string()),
            TypeRef::Optional { inner } if matches!(inner.as_ref(), TypeRef::Struct { .. }) => {
                if let TypeRef::Struct { name, .. } = inner.as_ref() {
                    out.push(format!("POINTER({})", c_type_name(prefix, name)));
                }
            }
            ty => match ty.unwrap_optional() {
                TypeRef::Callback { params } => {
                    out.push(callback_type(callbacks, params, prefix));
                    out.push("c_void_p".to_string());
                    out.push(RELEASE_USER_DATA_TYPE.to_string());
                }
                TypeRef::String | TypeRef::CString => out.push("c_char_p".to_string()),
                other => out.push(raw_type(other, prefix)),
            },
        }
    }
    out
}

/// Owned strings come back as `c_void_p`, so the runtime can free them after
/// copying; `c_char_p` would copy and drop the pointer.
fn return_ctype(ty: &TypeRef, prefix: &str) -> String {
    match ty.unwrap_optional() {
        TypeRef::Void => "None".to_string(),
        TypeRef::String | TypeRef::CString => "c_void_p".to_string(),
        other => raw_type(other, prefix),
    }
}

/// Registers the `CFUNCTYPE` for a callback signature and returns its name.
/// Callbacks are named after their signature: many share one.
fn callback_type(callbacks: &mut Callbacks, params: &[TypeRef], prefix: &str) -> String {
    let args: Vec<String> = params.iter().map(|ty| raw_type(ty, prefix)).collect();
    let stem: Vec<String> = args
        .iter()
        .map(|ty| {
            ty.trim_start_matches("c_")
                .trim_start_matches(prefix)
                .trim_end_matches("_t")
                .to_string()
        })
        .collect();
    let name = if stem.is_empty() {
        format!("{prefix}void_callback_t")
    } else {
        format!("{prefix}{}_callback_t", stem.join("_"))
    };
    let mut signature_args = vec!["None".to_string()];
    signature_args.extend(args);
    signature_args.push("c_void_p".to_string());
    callbacks.insert(
        name.clone(),
        format!("CFUNCTYPE({})", signature_args.join(", ")),
    );
    name
}

/// The `ctypes` type a C value of `ty` has, as a struct field or by-value
/// argument.
fn raw_type(ty: &TypeRef, prefix: &str) -> String {
    match ty {
        TypeRef::Void => "None".to_string(),
        TypeRef::Bool => "c_bool".to_string(),
        TypeRef::Int { name } => int_ctype(name).to_string(),
        TypeRef::Float { name } => if name == "float" {
            "c_float"
        } else {
            "c_double"
        }
        .to_string(),
        TypeRef::String | TypeRef::CString => "c_char_p".to_string(),
        TypeRef::Enum { .. } => "c_int".to_string(),
        TypeRef::Struct { name, .. } => c_type_name(prefix, name),
        TypeRef::Object { .. } => "c_uint64".to_string(),
        TypeRef::Alias { underlying, .. } => raw_type(underlying, prefix),
        TypeRef::Vector { element } => match element.as_ref() {
            TypeRef::Object { name, .. } => c_list_type_name(prefix, name),
            _ => STRING_LIST_TYPE.to_string(),
        },
        TypeRef::Map { .. } => STRING_MAP_TYPE.to_string(),
        TypeRef::Optional { inner } => raw_type(inner, prefix),
        TypeRef::Callback { .. } | TypeRef::RawPointer | TypeRef::Unsupported { .. } => {
            "c_void_p".to_string()
        }
    }
}

fn int_ctype(name: &str) -> &'static str {
    match name {
        "char" | "signed char" => "c_byte",
        "short" => "c_short",
        "int" => "c_int",
        "long" => "c_long",
        "long long" => "c_longlong",
        "unsigned char" => "c_ubyte",
        "unsigned short" => "c_ushort",
        "unsigned int" => "c_uint",
        "unsigned long" => "c_ulong",
        "unsigned long long" => "c_uint64",
        _ => "c_int",
    }
}

fn raw_field_name(name: &str) -> String {
    name.to_snake_case()
}

fn c_struct_method_symbol(prefix: &str, item: &Struct, method: &Method) -> String {
    format!(
        "{}{}_{}",
        prefix,
        item.name.to_snake_case(),
        method.name.to_snake_case()
    )
}

fn c_struct_constant(prefix: &str, struct_name: &str, constant: &str) -> String {
    format!(
        "{}_{}_{}",
        prefix.trim_end_matches('_').to_shouty_snake_case(),
        struct_name.to_shouty_snake_case(),
        constant.to_shouty_snake_case()
    )
}

fn emitted_group<'a>(api: &'a Api, class: &Class) -> Option<&'a EventGroup> {
    let event = class.event.as_ref()?;
    api.headers
        .iter()
        .flat_map(|header| header.events.iter())
        .find(|group| &group.name == event)
}

fn struct_owns_memory(api: &Api, name: &str) -> bool {
    api.headers
        .iter()
        .flat_map(|header| header.structs.iter())
        .any(|item| item.name == name && struct_has_owned_fields(item))
}

// ---------------------------------------------------------------------------
// <stem>.py: the public API
// ---------------------------------------------------------------------------

/// Per-module state: the header being rendered and the other modules its
/// code reaches into.
struct Module<'a> {
    api: &'a Api,
    stem: &'a str,
    origins: &'a TypeOrigins,
    prefix: &'a str,
    imports: BTreeSet<String>,
}

impl Module<'_> {
    /// A type name as this module spells it: bare when it is defined here,
    /// through the module alias (`_geometry.Point`) otherwise. Going through
    /// the module keeps import cycles between headers harmless: attributes
    /// are only looked up when the code runs.
    fn qual(&mut self, name: &str) -> String {
        match self.origins.get(name) {
            Some(stem) if stem != self.stem => {
                self.imports.insert(stem.clone());
                format!("_{stem}.{name}")
            }
            _ => name.to_string(),
        }
    }
}

fn public_module(api: &Api, header: &Header, origins: &TypeOrigins, prefix: &str) -> String {
    let mut module = Module {
        api,
        stem: &header.stem,
        origins,
        prefix,
        imports: BTreeSet::new(),
    };
    let mut body = String::new();

    let mut aliases = BTreeSet::new();
    for alias in &header.aliases {
        if aliases.insert(alias.name.clone()) {
            let underlying = annotation(&mut module, &alias.underlying, Position::Field);
            writeln!(body, "{} = {underlying}\n", alias.name).unwrap();
        }
    }
    if !aliases.is_empty() {
        body.push('\n');
    }
    for item in &header.enums {
        render_enum(&mut body, item);
    }
    for item in &header.structs {
        render_struct(&mut body, &mut module, item);
    }
    for group in &header.events {
        render_event(&mut body, &mut module, group);
    }
    for class in &header.classes {
        render_class(&mut body, &mut module, class);
    }

    let mut out = String::from(BANNER);
    let path = header.path.to_string_lossy();
    let name = path.rsplit("/src/").next().unwrap_or(&path);
    writeln!(out, "\"\"\"Generated from {name}.\"\"\"\n").unwrap();
    writeln!(out, "from __future__ import annotations\n").unwrap();
    // isort order: stdlib (`import x`, then `from x import`, alphabetically),
    // then the package's own modules.
    let mut stdlib = Vec::new();
    if body.contains("enum.") {
        stdlib.push("import enum".to_string());
    }
    if body.contains("Callable[") {
        stdlib.push("from collections.abc import Callable".to_string());
    }
    if body.contains("@dataclass") {
        let helpers = if body.contains("field(") {
            "dataclass, field"
        } else {
            "dataclass"
        };
        stdlib.push(format!("from dataclasses import {helpers}"));
    }
    if body.contains("ClassVar[") {
        stdlib.push("from typing import ClassVar".to_string());
    }
    let mut local = Vec::new();
    if body.contains("_C.") {
        local.push("from . import _capi as _C".to_string());
    }
    if body.contains("_rt.") {
        local.push("from . import _runtime as _rt".to_string());
    }
    for stem in &module.imports {
        local.push(format!("from . import {stem} as _{stem}"));
    }
    let groups: Vec<String> = [stdlib, local]
        .into_iter()
        .filter(|group| !group.is_empty())
        .map(|group| group.join("\n"))
        .collect();
    out.push_str(&groups.join("\n\n"));
    // Two blank lines before a class, one before a plain assignment.
    let body = body.trim();
    if body.starts_with("class ") || body.starts_with('@') {
        out.push_str("\n\n\n");
    } else {
        out.push_str("\n\n");
    }
    out.push_str(body);
    out.push('\n');
    out
}

// --- enums ---

fn render_enum(out: &mut String, item: &Enum) {
    let base = if is_flag_enum(item) {
        "IntFlag"
    } else {
        "IntEnum"
    };
    writeln!(out, "class {}(enum.{base}):", item.name).unwrap();
    for variant in &item.variants {
        writeln!(
            out,
            "    {} = {}",
            enum_member(&variant.name),
            variant.value
        )
        .unwrap();
    }
    writeln!(out, "\n").unwrap();
}

/// Bit flags: every non-zero value a distinct power of two, reaching past
/// what a plain `0, 1, 2` sequence would.
fn is_flag_enum(item: &Enum) -> bool {
    let values: Vec<i64> = item.variants.iter().map(|variant| variant.value).collect();
    values
        .iter()
        .all(|value| *value == 0 || (*value > 0 && value & (value - 1) == 0))
        && values.iter().any(|value| *value >= 4)
        && !values.contains(&3)
}

fn enum_member(name: &str) -> String {
    let name = name
        .strip_prefix('k')
        .filter(|rest| rest.starts_with(char::is_uppercase))
        .unwrap_or(name);
    name.to_shouty_snake_case()
}

// --- structs ---

fn render_struct(out: &mut String, module: &mut Module, item: &Struct) {
    let c_ty = format!("_C.{}", c_type_name(module.prefix, &item.name));
    writeln!(out, "@dataclass").unwrap();
    writeln!(out, "class {}:", item.name).unwrap();
    for field in &item.fields {
        let ty = match &field.ty {
            // Unset until the caller supplies one.
            TypeRef::Callback { .. } => {
                format!("{} | None", annotation(module, &field.ty, Position::Field))
            }
            other => annotation(module, other, Position::Field),
        };
        let default = field_default(module, &field.ty);
        writeln!(
            out,
            "    {}: {ty} = {default}",
            py_ident(&field.name.to_snake_case())
        )
        .unwrap();
    }
    for constant in &item.constants {
        writeln!(
            out,
            "    {}: ClassVar[{}]",
            constant.to_shouty_snake_case(),
            item.name
        )
        .unwrap();
    }
    writeln!(out).unwrap();

    // _from_c: copies a C value out; the caller frees it if it owns it.
    writeln!(out, "    @classmethod").unwrap();
    writeln!(out, "    def _from_c(cls, raw: {c_ty}) -> {}:", item.name).unwrap();
    let values: Vec<String> = item
        .fields
        .iter()
        .map(|field| match field.ty.unwrap_optional() {
            TypeRef::Callback { .. } => "None".to_string(),
            ty => borrowed_value(module, ty, &format!("raw.{}", raw_field_name(&field.name))),
        })
        .collect();
    write_call(out, "        return cls(", &values, ")");
    writeln!(out).unwrap();

    // _to_c: a C value borrowing from the Python one; ctypes keeps the
    // encoded strings and callbacks alive as long as the C value.
    writeln!(out, "    def _to_c(self) -> {c_ty}:").unwrap();
    writeln!(out, "        raw = {c_ty}()").unwrap();
    for field in &item.fields {
        let raw = format!("raw.{}", raw_field_name(&field.name));
        let value = format!("self.{}", py_ident(&field.name.to_snake_case()));
        match field.ty.unwrap_optional() {
            TypeRef::Callback { params } => {
                let cb_ty = format!(
                    "_C.{}",
                    callback_type(&mut Callbacks::new(), params, module.prefix)
                );
                let trampoline = callback_trampoline(module, params, "fn");
                writeln!(out, "        if {value} is not None:").unwrap();
                writeln!(out, "            fn = {value}").unwrap();
                write_call(
                    out,
                    &format!("            {raw} = _rt.make_callback("),
                    &[cb_ty, trampoline],
                    ")",
                );
                // Released by the core once it drops the callback.
                writeln!(
                    out,
                    "            raw.{} = _rt.user_data({raw})",
                    c_user_data_param(&field.name)
                )
                .unwrap();
                writeln!(
                    out,
                    "            raw.{} = _rt.release_user_data",
                    c_release_user_data_param(&field.name)
                )
                .unwrap();
            }
            ty => {
                writeln!(out, "        {raw} = {}", c_value(module, ty, &value)).unwrap();
            }
        }
    }
    writeln!(out, "        return raw").unwrap();

    for method in &item.methods {
        writeln!(out).unwrap();
        render_struct_method(out, module, item, method);
    }
    writeln!(out, "\n").unwrap();

    for constant in &item.constants {
        writeln!(
            out,
            "{}.{} = {}._from_c(_C.{})",
            item.name,
            constant.to_shouty_snake_case(),
            item.name,
            c_struct_constant(module.prefix, &item.name, constant)
        )
        .unwrap();
    }
    if !item.constants.is_empty() {
        writeln!(out, "\n").unwrap();
    }
}

fn render_struct_method(out: &mut String, module: &mut Module, item: &Struct, method: &Method) {
    let symbol = format!("_C.{}", c_struct_method_symbol(module.prefix, item, method));
    let name = py_ident(&method.name.to_snake_case());
    let ret = annotation(module, &method.return_type, Position::Return);
    let mut args: Vec<String> = Vec::new();
    if method.is_static {
        writeln!(out, "    @classmethod").unwrap();
        write_def(out, &name, "cls", &method.params, module, &ret);
    } else {
        write_def(out, &name, "self", &method.params, module, &ret);
        args.push("self._to_c()".to_string());
    }
    render_call_body(
        out,
        module,
        &symbol,
        args,
        &method.params,
        &method.return_type,
        "        ",
    );
}

// --- events ---

fn render_event(out: &mut String, module: &mut Module, group: &EventGroup) {
    let c_ty = format!("_C.{}", c_type_name(module.prefix, &group.name));
    writeln!(out, "@dataclass(frozen=True)").unwrap();
    writeln!(out, "class {}:", group.name).unwrap();
    writeln!(
        out,
        "    \"\"\"Base of every {}; listeners receive one of its subclasses.\"\"\"",
        group.name
    )
    .unwrap();
    writeln!(out).unwrap();
    for field in &group.common {
        let ty = annotation(module, &field.ty, Position::Field);
        writeln!(out, "    {}: {ty}", py_ident(&field.name.to_snake_case())).unwrap();
    }
    if !group.common.is_empty() {
        writeln!(out).unwrap();
    }
    writeln!(out, "    @staticmethod").unwrap();
    writeln!(
        out,
        "    def _from_c(raw: {c_ty}) -> {} | None:",
        group.name
    )
    .unwrap();
    let common: Vec<String> = group
        .common
        .iter()
        .map(|field| event_value(module, field, "raw"))
        .collect();
    for (index, variant) in group.variants.iter().enumerate() {
        let payload = format!("raw.data.{}", event_payload_field(&variant.discriminant));
        let mut values = common.clone();
        values.extend(
            variant
                .fields
                .iter()
                .map(|field| event_value(module, field, &payload)),
        );
        writeln!(out, "        if raw.type == {index}:").unwrap();
        write_call(
            out,
            &format!("            return {}(", variant.name),
            &values,
            ")",
        );
    }
    writeln!(out, "        return None").unwrap();
    writeln!(out, "\n").unwrap();

    for variant in &group.variants {
        writeln!(out, "@dataclass(frozen=True)").unwrap();
        writeln!(out, "class {}({}):", variant.name, group.name).unwrap();
        if variant.fields.is_empty() {
            writeln!(out, "    pass").unwrap();
        }
        for field in &variant.fields {
            let ty = annotation(module, &field.ty, Position::Field);
            writeln!(out, "    {}: {ty}", py_ident(&field.name.to_snake_case())).unwrap();
        }
        writeln!(out, "\n").unwrap();
    }
}

/// Event payloads are only valid during the callback, so everything is
/// copied out; handles become borrowed wrappers.
fn event_value(module: &mut Module, field: &Field, base: &str) -> String {
    borrowed_value(
        module,
        field.ty.unwrap_optional(),
        &format!("{base}.{}", raw_field_name(&field.name)),
    )
}

// --- classes ---

fn render_class(out: &mut String, module: &mut Module, class: &Class) {
    match class.kind {
        ClassKind::Instance => render_instance_class(out, module, class),
        ClassKind::Singleton => render_singleton_class(out, module, class),
    }
}

fn render_instance_class(out: &mut String, module: &mut Module, class: &Class) {
    let prefix = module.prefix;
    // A derived class inherits the base's handle plumbing (and `_free`, which
    // releases the same table slot): the C ABI resolves its handle as the base.
    let parent = class
        .base
        .clone()
        .unwrap_or_else(|| "_rt.NativeObject".to_string());
    writeln!(out, "class {}({parent}):", class.name).unwrap();
    writeln!(
        out,
        "    \"\"\"Owned reference to a native {}.\n\n    `dispose()` (or `with`) releases it; otherwise it is released when the\n    wrapper is garbage collected.\n    \"\"\"",
        class.name
    )
    .unwrap();
    writeln!(out).unwrap();
    writeln!(out, "    __slots__ = ()").unwrap();
    if class.base.is_none() {
        writeln!(
            out,
            "    _free = staticmethod(_C.{})",
            c_free_symbol(prefix, &class.name)
        )
        .unwrap();
    }

    let (default, named): (Vec<&Constructor>, Vec<&Constructor>) = class
        .constructors
        .iter()
        .partition(|ctor| constructor_suffix(class, ctor).is_none());
    if let Some(ctor) = default.first() {
        writeln!(out).unwrap();
        write_def(out, "__init__", "self", &ctor.params, module, "None");
        render_constructor_body(out, module, class, ctor, "self._adopt(handle)");
    }
    for ctor in named {
        let suffix = constructor_suffix(class, ctor).unwrap_or_default();
        writeln!(out).unwrap();
        writeln!(out, "    @classmethod").unwrap();
        let name = py_ident(&suffix.to_snake_case());
        write_def(out, &name, "cls", &ctor.params, module, &class.name);
        render_constructor_body(out, module, class, ctor, "return cls._owned(handle)");
    }

    for method in &class.methods {
        if c_method_symbol(module.prefix, class, method) == LOOP_RUN_WITH_WINDOW {
            // Folded into `run(window=None)`.
            continue;
        }
        writeln!(out).unwrap();
        render_method(out, module, class, method);
    }

    if class.native_object {
        writeln!(out).unwrap();
        writeln!(out, "    @property").unwrap();
        writeln!(out, "    def native_object(self) -> int | None:").unwrap();
        writeln!(
            out,
            "        \"\"\"The platform object behind this handle (NSWindow*, HWND, ...).\"\"\""
        )
        .unwrap();
        writeln!(
            out,
            "        return _C.{}(self._handle)",
            c_native_object_symbol(prefix, &class.name)
        )
        .unwrap();
    }

    render_setters(out, module, class);
    render_listener(out, module, class);
    writeln!(out, "\n").unwrap();
}

/// `obj.title = value` for every `GetTitle` property with a matching
/// one-argument `void SetTitle`. The `set_title()` method stays; setters are
/// rendered last so the property object they extend is already in place.
fn render_setters(out: &mut String, module: &mut Module, class: &Class) {
    for getter in &class.methods {
        if !(is_binding_accessor(class, getter) && getter.params.is_empty()) {
            continue;
        }
        let Some(stem) = getter.accessor_stem() else {
            continue;
        };
        let setter_name = format!("Set{stem}");
        let mut setters = class.methods.iter().filter(|m| m.name == setter_name);
        let (Some(setter), None) = (setters.next(), setters.next()) else {
            // Absent, or overloaded: no single setter to pick.
            continue;
        };
        if setter.is_static
            || setter.params.len() != 1
            || !matches!(setter.return_type, TypeRef::Void)
        {
            continue;
        }
        let property = py_method_name(class, getter);
        let method = py_method_name(class, setter);
        let ty = annotation(module, &setter.params[0].ty, Position::Param);
        writeln!(out).unwrap();
        writeln!(out, "    @{property}.setter").unwrap();
        write_def_raw(
            out,
            &property,
            &["self".to_string(), format!("value: {ty}")],
            "None",
        );
        writeln!(out, "        self.{method}(value)").unwrap();
    }
}

fn render_constructor_body(
    out: &mut String,
    module: &mut Module,
    class: &Class,
    ctor: &Constructor,
    finish: &str,
) {
    let symbol = format!("_C.{}", c_constructor_symbol(module.prefix, class, ctor));
    render_callback_locals(out, module, &ctor.params, "        ");
    let args = call_args(module, &ctor.params, Vec::new());
    write_call(out, &format!("        handle = {symbol}("), &args, ")");
    writeln!(out, "        if not handle:").unwrap();
    writeln!(
        out,
        "            raise _rt.NativeApiError(\"failed to create a {}\")",
        class.name
    )
    .unwrap();
    writeln!(out, "        {finish}").unwrap();
}

fn render_singleton_class(out: &mut String, module: &mut Module, class: &Class) {
    writeln!(out, "class {}:", class.name).unwrap();
    writeln!(
        out,
        "    \"\"\"The process-wide {}; every member is static.\"\"\"",
        class.name
    )
    .unwrap();
    writeln!(out).unwrap();
    writeln!(out, "    def __init__(self) -> None:").unwrap();
    writeln!(
        out,
        "        raise TypeError(\"{} is a singleton; call its static methods\")",
        class.name
    )
    .unwrap();
    for method in &class.methods {
        if c_method_symbol(module.prefix, class, method) == LOOP_RUN_WITH_WINDOW {
            // Folded into `run(window=None)`.
            continue;
        }
        writeln!(out).unwrap();
        render_method(out, module, class, method);
    }
    render_listener(out, module, class);
    writeln!(out, "\n").unwrap();
}

fn render_method(out: &mut String, module: &mut Module, class: &Class, method: &Method) {
    let symbol = c_method_symbol(module.prefix, class, method);
    if render_loop_method(out, module, &symbol) {
        return;
    }
    let instance = class.is_instance() && !method.is_static;
    let name = py_method_name(class, method);
    let ret = annotation(module, &method.return_type, Position::Return);
    let property = is_binding_accessor(class, method) && method.params.is_empty();

    if property {
        writeln!(out, "    @property").unwrap();
        writeln!(out, "    def {name}(self) -> {ret}:").unwrap();
    } else if instance {
        write_def(out, &name, "self", &method.params, module, &ret);
    } else {
        writeln!(out, "    @staticmethod").unwrap();
        write_def(out, &name, "", &method.params, module, &ret);
    }
    let receiver = if instance {
        vec!["self._handle".to_string()]
    } else {
        Vec::new()
    };
    render_call_body(
        out,
        module,
        &format!("_C.{symbol}"),
        receiver,
        &method.params,
        &method.return_type,
        "        ",
    );
}

/// `Application.run` / `quit` go through the runtime, which can also pump the
/// platform loop from asyncio. Returns false for every other symbol.
fn render_loop_method(out: &mut String, module: &mut Module, symbol: &str) -> bool {
    match symbol {
        LOOP_RUN => {
            let window = module.qual("Window");
            writeln!(out, "    @staticmethod").unwrap();
            writeln!(out, "    def run(window: {window} | None = None) -> int:").unwrap();
            writeln!(
                out,
                "        \"\"\"Runs the platform event loop until `quit()`; returns the exit code.\n\n        Blocks the calling thread, which must be the main thread. With `window`,\n        it is shown and made the primary window. See `run_async()` to keep an\n        asyncio loop running alongside.\n        \"\"\""
            )
            .unwrap();
            writeln!(out, "        return _rt.run_event_loop(window)").unwrap();
            writeln!(out).unwrap();
            writeln!(out, "    @staticmethod").unwrap();
            writeln!(
                out,
                "    async def run_async(window: {window} | None = None) -> int:"
            )
            .unwrap();
            writeln!(
                out,
                "        \"\"\"Pumps the platform event loop from the running asyncio loop until\n        `quit()`; resolves with the exit code.\n\n        Tasks, timers and I/O keep running while windows are up. Must be awaited\n        on the main thread.\n        \"\"\""
            )
            .unwrap();
            writeln!(out, "        return await _rt.run_event_loop_async(window)").unwrap();
            true
        }
        LOOP_QUIT => {
            writeln!(out, "    @staticmethod").unwrap();
            writeln!(out, "    def quit(exit_code: int = 0) -> None:").unwrap();
            writeln!(
                out,
                "        \"\"\"Stops the loop started by `run()` or `run_async()`, which then\n        returns `exit_code`.\"\"\""
            )
            .unwrap();
            writeln!(out, "        _rt.quit_event_loop(exit_code)").unwrap();
            true
        }
        _ => false,
    }
}

fn render_listener(out: &mut String, module: &mut Module, class: &Class) {
    let Some(group) = emitted_group(module.api, class) else {
        return;
    };
    let prefix = module.prefix;
    let event = module.qual(&group.name);
    let add = c_add_listener_symbol(prefix, &class.name);
    let remove = c_remove_listener_symbol(prefix, &class.name);
    let callback_ty = event_callback_type(prefix, &group.name);
    let (decorator, receiver_param) = if class.is_instance() {
        ("", "self, ")
    } else {
        ("    @staticmethod\n", "")
    };

    writeln!(out).unwrap();
    out.push_str(decorator);
    writeln!(
        out,
        "    def add_listener({receiver_param}callback: Callable[[{event}], None]) -> int:"
    )
    .unwrap();
    writeln!(
        out,
        "        \"\"\"Calls `callback` with every {} this {} emits.\n\n        Returns the listener id for `remove_listener()`.\n        \"\"\"",
        group.name, class.name
    )
    .unwrap();
    writeln!(out).unwrap();
    writeln!(out, "        def trampoline(raw, _user_data):").unwrap();
    writeln!(out, "            event = {event}._from_c(raw.contents)").unwrap();
    writeln!(out, "            if event is not None:").unwrap();
    writeln!(out, "                callback(event)").unwrap();
    writeln!(out).unwrap();
    let mut add_args = vec![
        format!("_C.{add}"),
        format!("_C.{callback_ty}"),
        "trampoline".to_string(),
    ];
    if class.is_instance() {
        add_args.push("self._handle".to_string());
    }
    write_call(out, "        return _rt.add_listener(", &add_args, ")");
    writeln!(out).unwrap();
    out.push_str(decorator);
    writeln!(
        out,
        "    def remove_listener({receiver_param}listener_id: int) -> bool:"
    )
    .unwrap();
    writeln!(
        out,
        "        \"\"\"Unregisters a listener. Returns False if unknown.\"\"\""
    )
    .unwrap();
    let mut remove_args = vec![format!("_C.{remove}"), "listener_id".to_string()];
    if class.is_instance() {
        remove_args.push("self._handle".to_string());
    }
    write_call(
        out,
        "        return _rt.remove_listener(",
        &remove_args,
        ")",
    );
}

// --- calls ---

/// The call of `symbol` plus the conversion of its result.
fn render_call_body(
    out: &mut String,
    module: &mut Module,
    symbol: &str,
    receiver: Vec<String>,
    params: &[Param],
    ret: &TypeRef,
    indent: &str,
) {
    render_callback_locals(out, module, params, indent);
    let args = call_args(module, params, receiver);
    match ret {
        TypeRef::Void => write_call(out, &format!("{indent}{symbol}("), &args, ")"),
        _ => {
            write_call(out, &format!("{indent}raw = {symbol}("), &args, ")");
            render_return(out, module, ret, indent);
        }
    }
}

/// `native_<param>`: the C function pointer for each callback parameter,
/// which `call_args` passes on together with its `user_data` key.
fn render_callback_locals(out: &mut String, module: &mut Module, params: &[Param], indent: &str) {
    for param in params {
        if let TypeRef::Callback { params: args } = param.ty.unwrap_optional() {
            let name = py_ident(&param.name.to_snake_case());
            let trampoline = callback_trampoline(module, args, &name);
            let cb_ty = format!(
                "_C.{}",
                callback_type(&mut Callbacks::new(), args, module.prefix)
            );
            if matches!(param.ty, TypeRef::Optional { .. }) {
                // ctypes rejects None for a CFUNCTYPE argument; an empty
                // instance is the NULL function pointer.
                writeln!(out, "{indent}native_{name} = {cb_ty}()").unwrap();
                writeln!(out, "{indent}if {name} is not None:").unwrap();
                write_call(
                    out,
                    &format!("{indent}    native_{name} = _rt.make_callback("),
                    &[cb_ty, trampoline],
                    ")",
                );
            } else {
                write_call(
                    out,
                    &format!("{indent}native_{name} = _rt.make_callback("),
                    &[cb_ty, trampoline],
                    ")",
                );
            }
        }
    }
}

fn render_return(out: &mut String, module: &mut Module, ty: &TypeRef, indent: &str) {
    let prefix = module.prefix;
    let value = match ty {
        TypeRef::String | TypeRef::CString => "_rt.take_str(raw)".to_string(),
        TypeRef::Optional { inner }
            if matches!(inner.as_ref(), TypeRef::String | TypeRef::CString) =>
        {
            "_rt.take_optional_str(raw)".to_string()
        }
        TypeRef::Optional { inner } => {
            return render_return(out, module, inner, indent);
        }
        TypeRef::Struct { name, .. } if struct_owns_memory(module.api, name) => {
            let ty = module.qual(name);
            writeln!(out, "{indent}value = {ty}._from_c(raw)").unwrap();
            writeln!(
                out,
                "{indent}_C.{}(_rt.byref(raw))",
                c_free_symbol(prefix, name)
            )
            .unwrap();
            writeln!(out, "{indent}return value").unwrap();
            return;
        }
        TypeRef::Struct { name, .. } => format!("{}._from_c(raw)", module.qual(name)),
        TypeRef::Enum { name, .. } => format!("_rt.to_enum({}, raw)", module.qual(name)),
        TypeRef::Object { name, .. } => format!("{}._owned(raw)", module.qual(name)),
        TypeRef::Vector { element } => match element.as_ref() {
            TypeRef::Object { name, .. } => format!(
                "_rt.take_handles(raw, raw.{}, {}, _C.{})",
                c_list_field(name),
                module.qual(name),
                c_list_release_symbol(prefix, name)
            ),
            _ => "_rt.take_str_list(raw)".to_string(),
        },
        TypeRef::Map { .. } => "_rt.take_str_map(raw)".to_string(),
        _ => "raw".to_string(),
    };
    if indent.len() + 7 + value.len() > 88 {
        if let Some((callee, rest)) = value.split_once('(') {
            let args: Vec<String> = split_args(rest.strip_suffix(')').unwrap_or(rest));
            write_call(out, &format!("{indent}return {callee}("), &args, ")");
            return;
        }
    }
    writeln!(out, "{indent}return {value}").unwrap();
}

/// Top-level comma-separated arguments of a call.
fn split_args(args: &str) -> Vec<String> {
    let mut out = Vec::new();
    let mut depth = 0;
    let mut current = String::new();
    for c in args.chars() {
        match c {
            '(' | '[' => depth += 1,
            ')' | ']' => depth -= 1,
            ',' if depth == 0 => {
                out.push(current.trim().to_string());
                current.clear();
                continue;
            }
            _ => {}
        }
        current.push(c);
    }
    if !current.trim().is_empty() {
        out.push(current.trim().to_string());
    }
    out
}

/// Arguments for a C call, receiver first; a callback expands into the
/// function pointer, its `user_data` key, and the release that drops it.
fn call_args(module: &mut Module, params: &[Param], receiver: Vec<String>) -> Vec<String> {
    let mut args = receiver;
    for param in params {
        let name = py_ident(&param.name.to_snake_case());
        match &param.ty {
            TypeRef::Optional { inner } => match inner.as_ref() {
                TypeRef::Struct { .. } => args.push(format!(
                    "None if {name} is None else _rt.byref({name}._to_c())"
                )),
                TypeRef::Callback { .. } => {
                    args.push(format!("native_{name}"));
                    args.push(format!("_rt.user_data(native_{name})"));
                    args.push("_rt.release_user_data".to_string());
                }
                TypeRef::String | TypeRef::CString => {
                    args.push(format!("_rt.encode_optional({name})"))
                }
                TypeRef::Object { .. } => args.push(format!("_rt.handle_of({name})")),
                other => args.push(c_value(module, other, &name)),
            },
            TypeRef::Callback { .. } => {
                args.push(format!("native_{name}"));
                args.push(format!("_rt.user_data(native_{name})"));
                args.push("_rt.release_user_data".to_string());
            }
            other => args.push(c_value(module, other, &name)),
        }
    }
    args
}

/// A Python value converted for C: a struct field assignment or a by-value
/// argument.
fn c_value(module: &mut Module, ty: &TypeRef, value: &str) -> String {
    match ty {
        TypeRef::String | TypeRef::CString => format!("_rt.encode({value})"),
        TypeRef::Enum { .. } => format!("int({value})"),
        TypeRef::Struct { .. } => format!("{value}._to_c()"),
        TypeRef::Object { shared: true, .. } => format!("_rt.handle_of({value})"),
        TypeRef::Object { .. } => format!("{value}._handle"),
        TypeRef::Vector { element } => match element.as_ref() {
            TypeRef::Object { .. } => format!("_rt.handle_list({value})"),
            _ => format!("_rt.str_list({value})"),
        },
        TypeRef::Map { .. } => format!("_rt.str_map({value})"),
        TypeRef::Optional { inner } => match inner.as_ref() {
            TypeRef::String | TypeRef::CString => format!("_rt.encode_optional({value})"),
            TypeRef::Object { .. } => format!("_rt.handle_of({value})"),
            other => c_value(module, other, value),
        },
        _ => value.to_string(),
    }
}

/// A C value read into Python without taking ownership of it.
fn borrowed_value(module: &mut Module, ty: &TypeRef, access: &str) -> String {
    match ty {
        TypeRef::Bool => format!("bool({access})"),
        TypeRef::String | TypeRef::CString => format!("_rt.decode({access})"),
        TypeRef::Enum { name, .. } => format!("_rt.to_enum({}, {access})", module.qual(name)),
        TypeRef::Struct { name, .. } => format!("{}._from_c({access})", module.qual(name)),
        TypeRef::Object { name, .. } => format!("{}._borrowed({access})", module.qual(name)),
        TypeRef::Vector { element } => match element.as_ref() {
            TypeRef::Object { name, .. } => format!(
                "_rt.read_handles({access}.{}, {access}.count, {})",
                c_list_field(name),
                module.qual(name)
            ),
            _ => format!("_rt.read_str_list({access})"),
        },
        TypeRef::Map { .. } => format!("_rt.read_str_map({access})"),
        TypeRef::Optional { inner } => borrowed_value(module, inner, access),
        _ => access.to_string(),
    }
}

/// A lambda turning the C arguments of a callback into the Python ones.
fn callback_trampoline(module: &mut Module, params: &[TypeRef], target: &str) -> String {
    let names: Vec<String> = (0..params.len()).map(|index| format!("a{index}")).collect();
    let values: Vec<String> = params
        .iter()
        .zip(&names)
        .map(|(ty, name)| borrowed_value(module, ty, name))
        .collect();
    let mut lambda_params = names;
    lambda_params.push("_user_data".to_string());
    format!(
        "lambda {}: {target}({})",
        lambda_params.join(", "),
        values.join(", ")
    )
}

/// `def name(receiver, params) -> ret:` at class level, one parameter per
/// line when it would not fit.
fn write_def(
    out: &mut String,
    name: &str,
    receiver: &str,
    params: &[Param],
    module: &mut Module,
    ret: &str,
) {
    let mut parts: Vec<String> = Vec::new();
    if !receiver.is_empty() {
        parts.push(receiver.to_string());
    }
    for param in params {
        parts.push(format!(
            "{}: {}",
            py_ident(&param.name.to_snake_case()),
            annotation(module, &param.ty, Position::Param)
        ));
    }
    write_def_raw(out, name, &parts, ret);
}

/// `write_def` over already rendered parameters.
fn write_def_raw(out: &mut String, name: &str, parts: &[String], ret: &str) {
    let line = format!("    def {name}({}) -> {ret}:", parts.join(", "));
    if line.len() <= 88 {
        writeln!(out, "{line}").unwrap();
        return;
    }
    writeln!(out, "    def {name}(").unwrap();
    for part in parts {
        writeln!(out, "        {part},").unwrap();
    }
    writeln!(out, "    ) -> {ret}:").unwrap();
}

/// `head` + comma-separated `values` + `tail`, wrapped one value per line
/// when it would not fit.
fn write_call(out: &mut String, head: &str, values: &[String], tail: &str) {
    let line = format!("{head}{}{tail}", values.join(", "));
    if line.len() <= 88 || values.is_empty() {
        writeln!(out, "{line}").unwrap();
        return;
    }
    let indent: String = head.chars().take_while(|c| *c == ' ').collect();
    writeln!(out, "{head}").unwrap();
    for value in values {
        writeln!(out, "{indent}    {value},").unwrap();
    }
    writeln!(out, "{indent}{tail}").unwrap();
}

// --- types ---

#[derive(Clone, Copy, PartialEq)]
enum Position {
    Param,
    Return,
    Field,
}

fn annotation(module: &mut Module, ty: &TypeRef, position: Position) -> String {
    match ty {
        TypeRef::Void => "None".to_string(),
        TypeRef::Bool => "bool".to_string(),
        TypeRef::Int { .. } => "int".to_string(),
        TypeRef::Float { .. } => "float".to_string(),
        TypeRef::String | TypeRef::CString => "str".to_string(),
        TypeRef::Alias { name, .. } | TypeRef::Enum { name, .. } | TypeRef::Struct { name, .. } => {
            module.qual(name)
        }
        TypeRef::Object { name, shared, .. } => {
            let name = module.qual(name);
            if position == Position::Param && !shared {
                name
            } else {
                format!("{name} | None")
            }
        }
        TypeRef::Vector { element } => match element.as_ref() {
            TypeRef::Object { name, .. } => format!("list[{}]", module.qual(name)),
            _ => "list[str]".to_string(),
        },
        TypeRef::Map { .. } => "dict[str, str]".to_string(),
        TypeRef::Optional { inner } => {
            let base = annotation(module, inner, position);
            if base.ends_with("| None") {
                base
            } else {
                format!("{base} | None")
            }
        }
        TypeRef::Callback { params } => {
            let args: Vec<String> = params
                .iter()
                .map(|param| annotation(module, param, Position::Field))
                .collect();
            format!("Callable[[{}], None]", args.join(", "))
        }
        TypeRef::RawPointer => "int | None".to_string(),
        TypeRef::Unsupported { .. } => "object".to_string(),
    }
}

/// Default for a dataclass field, so value types can be built from keywords.
fn field_default(module: &mut Module, ty: &TypeRef) -> String {
    match ty {
        TypeRef::Bool => "False".to_string(),
        TypeRef::Int { .. } => "0".to_string(),
        TypeRef::Float { .. } => "0.0".to_string(),
        TypeRef::String | TypeRef::CString => "\"\"".to_string(),
        TypeRef::Alias { underlying, .. } => field_default(module, underlying),
        TypeRef::Enum { name, .. } => {
            let first = module
                .api
                .headers
                .iter()
                .flat_map(|header| header.enums.iter())
                .find(|item| &item.name == name)
                .and_then(|item| item.variants.first())
                .map(|variant| enum_member(&variant.name));
            let name = module.qual(name);
            match first {
                Some(member) => format!("field(default_factory=lambda: {name}.{member})"),
                None => format!("field(default_factory=lambda: {name}(0))"),
            }
        }
        TypeRef::Struct { name, .. } => {
            format!("field(default_factory=lambda: {}())", module.qual(name))
        }
        TypeRef::Vector { .. } => "field(default_factory=list)".to_string(),
        TypeRef::Map { .. } => "field(default_factory=dict)".to_string(),
        _ => "None".to_string(),
    }
}

fn py_method_name(class: &Class, method: &Method) -> String {
    let base = if is_binding_accessor(class, method) {
        method.binding_name()
    } else {
        &method.name
    };
    let mut name = base.to_snake_case();
    let overloaded = class
        .methods
        .iter()
        .filter(|other| other.name == method.name)
        .count()
        > 1;
    if overloaded && !method.params.is_empty() {
        name = format!(
            "{name}_with_{}",
            method
                .params
                .iter()
                .map(|param| param.name.to_snake_case())
                .collect::<Vec<_>>()
                .join("_and_")
        );
    }
    if class.is_instance() && NATIVE_OBJECT_MEMBERS.contains(&name.as_str()) {
        // Would shadow the handle management every wrapper inherits.
        return format!("{name}_");
    }
    py_ident(&name)
}

/// Public members of `_runtime.NativeObject`.
const NATIVE_OBJECT_MEMBERS: &[&str] = &["dispose", "native_handle"];

const PYTHON_KEYWORDS: &[&str] = &[
    "False", "None", "True", "and", "as", "assert", "async", "await", "break", "class", "continue",
    "def", "del", "elif", "else", "except", "finally", "for", "from", "global", "if", "import",
    "in", "is", "lambda", "nonlocal", "not", "or", "pass", "raise", "return", "try", "while",
    "with", "yield",
];

fn py_ident(name: &str) -> String {
    if PYTHON_KEYWORDS.contains(&name) {
        format!("{name}_")
    } else {
        name.to_string()
    }
}
