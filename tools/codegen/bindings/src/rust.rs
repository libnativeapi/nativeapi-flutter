use std::fmt::Write;
use std::path::Path;

use heck::{ToSnakeCase, ToUpperCamelCase};

use codegen_shared::ir::{
    Api, Class, Constructor, EventGroup, Field, Header, Method, Param, Struct, TypeRef,
};
use codegen_shared::naming::{
    c_add_listener_symbol, c_constructor_symbol, c_event_variant, c_free_symbol, c_list_field,
    c_list_release_symbol, c_method_symbol, c_native_object_symbol, c_remove_listener_symbol,
    c_type_name, foreign_types, rust_constructor_name, rust_enum_variant, rust_ident,
    rust_int_type, rust_method_name, rust_public_type, struct_has_owned_fields, TypeOrigins,
    STRING_FREE_FN, STRING_LIST_FREE_FN, STRING_MAP_FREE_FN,
};
use codegen_shared::GeneratedFile;

pub fn generate(
    api: &Api,
    header: &Header,
    origins: &TypeOrigins,
    rust_out: &Path,
    prefix: &str,
) -> GeneratedFile {
    GeneratedFile {
        path: rust_out.join(format!("{}.rs", header.stem)),
        contents: render_rust_wrapper(api, header, origins, prefix),
    }
}

/// The crate's module list. `lib.rs` stays hand-written — it also holds the
/// crate's error type — and pulls this in with `include!("modules.rs");`.
pub fn generate_modules(api: &Api, origins: &TypeOrigins, rust_out: &Path) -> GeneratedFile {
    let mut out = String::new();
    writeln!(out, "// AUTO-GENERATED. DO NOT EDIT.").unwrap();
    writeln!(
        out,
        "// Any manual changes WILL BE LOST when this file is regenerated."
    )
    .unwrap();
    writeln!(out).unwrap();
    writeln!(
        out,
        "// Pulled into lib.rs with `include!(\"modules.rs\");`."
    )
    .unwrap();
    writeln!(out).unwrap();
    let mut modules: Vec<(&str, Vec<String>)> = api
        .headers
        .iter()
        .map(|header| (header.stem.as_str(), reexports(header, origins)))
        .collect();
    modules.sort_unstable_by_key(|(stem, _)| *stem);

    for (stem, _) in &modules {
        writeln!(out, "pub mod {stem};").unwrap();
    }
    writeln!(out).unwrap();
    writeln!(
        out,
        "// Flat re-exports, so `use nativeapi::Display;` works alongside"
    )
    .unwrap();
    writeln!(out, "// `use nativeapi::display::Display;`.").unwrap();
    for (stem, names) in &modules {
        if names.is_empty() {
            continue;
        }
        writeln!(out, "pub use {stem}::{{{}}};", names.join(", ")).unwrap();
    }
    GeneratedFile {
        path: rust_out.join("modules.rs"),
        contents: out,
    }
}

/// Type names this header owns, in the order they appear. A name declared in
/// several modules (`ListenerId`) is left out: re-exporting it twice would be
/// ambiguous, and it is a plain integer alias anyway.
fn reexports(header: &Header, origins: &TypeOrigins) -> Vec<String> {
    let mut names: Vec<String> = Vec::new();
    let owns = |name: &str| origins.get(name).map(String::as_str) == Some(header.stem.as_str());

    for alias in &header.aliases {
        if owns(&alias.name) {
            names.push(alias.name.clone());
        }
    }
    for item in &header.enums {
        names.push(item.name.clone());
    }
    for item in &header.structs {
        names.push(item.name.clone());
    }
    for group in &header.events {
        names.push(group.name.clone());
    }
    for class in &header.classes {
        names.push(class.name.clone());
        if class.is_instance() {
            names.push(format!("{}Ref", class.name));
        }
    }
    names
}

fn render_rust_wrapper(api: &Api, header: &Header, origins: &TypeOrigins, prefix: &str) -> String {
    let mut out = String::new();
    writeln!(out, "// AUTO-GENERATED. DO NOT EDIT.").unwrap();
    writeln!(
        out,
        "// Any manual changes WILL BE LOST when this file is regenerated."
    )
    .unwrap();
    writeln!(out, "#![allow(dead_code)]").unwrap();
    writeln!(out, "#![allow(unused_imports)]").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "use cnativeapi;").unwrap();
    writeln!(out, "use std::ffi::{{CStr, CString}};").unwrap();
    writeln!(out).unwrap();

    // Types owned by other generated modules of this crate.
    let mut imports: Vec<(String, String)> = foreign_types(header, origins)
        .into_iter()
        .filter_map(|name| origins.get(&name).map(|stem| (stem.clone(), name)))
        .collect();
    imports.sort();
    imports.dedup();
    if !imports.is_empty() {
        let mut current = String::new();
        let mut names: Vec<String> = Vec::new();
        for (module, name) in imports {
            if current != module {
                write_use(&mut out, &current, &names);
                current = module;
                names = Vec::new();
            }
            names.push(name);
        }
        write_use(&mut out, &current, &names);
        writeln!(out).unwrap();
    }

    if header.classes.iter().any(|class| class.event.is_some()) {
        writeln!(out, "/// Identifies one registered event listener.").unwrap();
        writeln!(
            out,
            "pub type ListenerId = cnativeapi::native_listener_id_t;"
        )
        .unwrap();
        writeln!(out).unwrap();
    }

    for alias in &header.aliases {
        if origins.get(&alias.name).map(String::as_str) != Some(header.stem.as_str()) {
            continue;
        }
        writeln!(
            out,
            "pub type {} = {};",
            alias.name,
            rust_public_type(&alias.underlying)
        )
        .unwrap();
        writeln!(out).unwrap();
    }

    for item in &header.enums {
        render_rust_enum(&mut out, item, prefix);
    }

    for item in &header.structs {
        render_rust_struct(&mut out, item, prefix);
    }

    for group in &header.events {
        render_rust_event(&mut out, group, prefix);
    }

    for class in &header.classes {
        if class.is_instance() {
            render_rust_handle_type(&mut out, class, prefix);
        } else {
            writeln!(out, "pub struct {};", class.name).unwrap();
            writeln!(out).unwrap();
        }

        writeln!(out, "impl {} {{", class.name).unwrap();
        if class.is_instance() {
            render_rust_handle_helpers(&mut out, class, prefix);
        }
        for ctor in &class.constructors {
            render_rust_constructor(&mut out, class, ctor, prefix);
        }
        for method in &class.methods {
            render_rust_method(&mut out, class, method, header, prefix);
        }
        if class.is_instance() && class.native_object {
            render_rust_native_object(&mut out, class, prefix);
        }
        render_rust_listener(&mut out, api, class, prefix);
        writeln!(out, "}}").unwrap();
        writeln!(out).unwrap();

        if class.is_instance() {
            render_rust_drop(&mut out, class, prefix);
        }
    }

    out
}

fn write_use(out: &mut String, module: &str, names: &[String]) {
    if module.is_empty() || names.is_empty() {
        return;
    }
    if names.len() == 1 {
        writeln!(out, "use crate::{module}::{};", names[0]).unwrap();
    } else {
        writeln!(out, "use crate::{module}::{{{}}};", names.join(", ")).unwrap();
    }
}

// ---------------------------------------------------------------------------
// Enums and structs
// ---------------------------------------------------------------------------

fn render_rust_enum(out: &mut String, item: &codegen_shared::ir::Enum, prefix: &str) {
    writeln!(out, "#[repr(i32)]").unwrap();
    writeln!(out, "#[derive(Debug, Copy, Clone, PartialEq, Eq)]").unwrap();
    writeln!(out, "pub enum {} {{", item.name).unwrap();
    for variant in &item.variants {
        writeln!(
            out,
            "    {} = {},",
            rust_enum_variant(&variant.name),
            variant.value
        )
        .unwrap();
    }
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    let c_ty = format!("cnativeapi::{}", c_type_name(prefix, &item.name));
    writeln!(out, "impl {} {{", item.name).unwrap();
    writeln!(out, "    pub(crate) fn from_raw(raw: {c_ty}) -> Self {{").unwrap();
    writeln!(out, "        match raw {{").unwrap();
    for variant in &item.variants {
        writeln!(
            out,
            "            cnativeapi::{} => Self::{},",
            c_enum_variant_const(prefix, item, &variant.name),
            rust_enum_variant(&variant.name)
        )
        .unwrap();
    }
    let fallback = item
        .variants
        .first()
        .map(|variant| rust_enum_variant(&variant.name))
        .unwrap_or_else(|| "Unknown".to_string());
    writeln!(out, "            _ => Self::{fallback},").unwrap();
    writeln!(out, "        }}").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "    pub(crate) fn to_raw(self) -> {c_ty} {{").unwrap();
    writeln!(out, "        self as {c_ty}").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

/// bindgen keeps the C spelling for enum constants.
fn c_enum_variant_const(prefix: &str, item: &codegen_shared::ir::Enum, variant: &str) -> String {
    codegen_shared::naming::c_enum_variant(prefix, item, variant)
}

fn render_rust_struct(out: &mut String, item: &Struct, prefix: &str) {
    // A callback field holds a closure, which is neither printable nor
    // comparable, so those derives have to go when one is present.
    let derives = if item.fields.iter().any(|field| is_callback(&field.ty)) {
        "#[derive(Clone)]"
    } else if struct_has_float_fields(item) {
        "#[derive(Debug, Clone, PartialEq)]"
    } else {
        "#[derive(Debug, Clone, PartialEq, Eq)]"
    };
    writeln!(out, "{derives}").unwrap();
    writeln!(out, "pub struct {} {{", item.name).unwrap();
    for field in &item.fields {
        if is_callback(&field.ty) {
            // A callback field is set by the caller, never read back; the
            // wrapper stores the closure and installs it in `to_raw`.
            writeln!(
                out,
                "    pub {}: Option<std::sync::Arc<dyn Fn({})>>,",
                rust_ident(&field.name.to_snake_case()),
                callback_signature(&field.ty)
            )
            .unwrap();
            continue;
        }
        writeln!(
            out,
            "    pub {}: {},",
            rust_ident(&field.name.to_snake_case()),
            rust_public_type(&field.ty)
        )
        .unwrap();
    }
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    let ffi_struct = format!("cnativeapi::{}", c_type_name(prefix, &item.name));
    writeln!(out, "impl {} {{", item.name).unwrap();
    writeln!(
        out,
        "    pub(crate) unsafe fn from_raw(raw: &{ffi_struct}) -> Self {{"
    )
    .unwrap();
    writeln!(out, "        Self {{").unwrap();
    for field in &item.fields {
        let name = rust_ident(&field.name.to_snake_case());
        let raw = field.name.to_snake_case();
        match &field.ty {
            TypeRef::String | TypeRef::CString => {
                writeln!(out, "            {name}: if raw.{raw}.is_null() {{ None }} else {{ Some(CStr::from_ptr(raw.{raw}).to_string_lossy().into_owned()) }},").unwrap();
            }
            TypeRef::Enum {
                name: enum_name, ..
            } => {
                writeln!(out, "            {name}: {enum_name}::from_raw(raw.{raw}),").unwrap();
            }
            TypeRef::Struct {
                name: struct_name, ..
            } => {
                writeln!(
                    out,
                    "            {name}: {struct_name}::from_raw(&raw.{raw}),"
                )
                .unwrap();
            }
            TypeRef::Callback { .. } => {
                writeln!(out, "            {name}: None,").unwrap();
            }
            _ => {
                writeln!(out, "            {name}: raw.{raw},").unwrap();
            }
        }
    }
    writeln!(out, "        }}").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out).unwrap();

    // The reverse direction: needed wherever a struct crosses as a parameter.
    writeln!(
        out,
        "    pub(crate) fn to_raw(&self) -> RawOf{} {{",
        item.name
    )
    .unwrap();
    writeln!(out, "        let mut raw = {ffi_struct}::default();").unwrap();
    let mut owned = Vec::new();
    for field in &item.fields {
        let name = rust_ident(&field.name.to_snake_case());
        let raw = field.name.to_snake_case();
        match &field.ty {
            TypeRef::String | TypeRef::CString => {
                writeln!(
                    out,
                    "        let {raw}_owned = self.{name}.as_deref().map(|value| CString::new(value).unwrap_or_default());"
                )
                .unwrap();
                writeln!(
                    out,
                    "        raw.{raw} = {raw}_owned.as_ref().map_or(std::ptr::null_mut(), |value| value.as_ptr() as *mut _);"
                )
                .unwrap();
                owned.push(format!("{raw}_owned"));
            }
            TypeRef::Enum { .. } => {
                writeln!(out, "        raw.{raw} = self.{name}.to_raw();").unwrap();
            }
            TypeRef::Struct { .. } => {
                writeln!(out, "        let {raw}_nested = self.{name}.to_raw();").unwrap();
                writeln!(out, "        raw.{raw} = {raw}_nested.raw;").unwrap();
                owned.push(format!("{raw}_nested"));
            }
            TypeRef::Callback { params } => {
                let user_data = codegen_shared::naming::c_user_data_param(&field.name);
                writeln!(out, "        if let Some(callback) = &self.{name} {{").unwrap();
                render_callback_trampoline(out, params, "            ");
                writeln!(
                    out,
                    "            raw.{raw} = Some(trampoline);\n            raw.{user_data} = leak_callback(callback.clone());"
                )
                .unwrap();
                writeln!(out, "        }}").unwrap();
            }
            _ => {
                writeln!(out, "        raw.{raw} = self.{name};").unwrap();
            }
        }
    }
    writeln!(out, "        RawOf{} {{ raw, _owned: ({}) }}", item.name, {
        let mut parts = owned.clone();
        if parts.len() == 1 {
            parts.push(String::new());
            parts[1] = "()".to_string();
        }
        parts.join(", ")
    })
    .unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    // Anything the raw struct points at has to outlive the call, so `to_raw`
    // hands back the backing storage alongside the struct instead of dangling.
    writeln!(
        out,
        "/// `{}` in its C form, keeping any borrowed buffers alive.",
        item.name
    )
    .unwrap();
    writeln!(out, "pub(crate) struct RawOf{} {{", item.name).unwrap();
    writeln!(out, "    pub(crate) raw: {ffi_struct},").unwrap();
    writeln!(out, "    _owned: ({}),", owned_tuple_type(item)).unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

fn owned_tuple_type(item: &Struct) -> String {
    let mut parts: Vec<String> = Vec::new();
    for field in &item.fields {
        match &field.ty {
            TypeRef::String | TypeRef::CString => parts.push("Option<CString>".to_string()),
            TypeRef::Struct { name, .. } => parts.push(format!("RawOf{name}")),
            _ => {}
        }
    }
    if parts.len() == 1 {
        parts.push("()".to_string());
    }
    parts.join(", ")
}

fn struct_has_float_fields(item: &Struct) -> bool {
    item.fields
        .iter()
        .any(|field| matches!(field.ty, TypeRef::Float { .. }))
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

fn render_rust_event(out: &mut String, group: &EventGroup, prefix: &str) {
    writeln!(out, "/// One `{}`, in its concrete form.", group.name).unwrap();
    writeln!(out, "#[derive(Debug, Clone, PartialEq)]").unwrap();
    writeln!(out, "pub enum {} {{", group.name).unwrap();
    for variant in &group.variants {
        let fields: Vec<String> = group
            .common
            .iter()
            .chain(variant.fields.iter())
            .map(|field| {
                format!(
                    "{}: {}",
                    rust_ident(&field.name.to_snake_case()),
                    rust_event_field_type(&field.ty)
                )
            })
            .collect();
        if fields.is_empty() {
            writeln!(out, "    {},", variant.discriminant.to_upper_camel_case()).unwrap();
        } else {
            writeln!(
                out,
                "    {} {{ {} }},",
                variant.discriminant.to_upper_camel_case(),
                fields.join(", ")
            )
            .unwrap();
        }
    }
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    let raw_ty = format!("cnativeapi::{}", c_type_name(prefix, &group.name));
    writeln!(out, "impl {} {{", group.name).unwrap();
    writeln!(
        out,
        "    pub(crate) unsafe fn from_raw(raw: &{raw_ty}) -> Option<Self> {{"
    )
    .unwrap();
    writeln!(out, "        Some(match raw.type_ {{").unwrap();
    for variant in &group.variants {
        let payload = c_event_variant_field(&variant.discriminant);
        let mut fields: Vec<String> = Vec::new();
        for field in &group.common {
            fields.push(format!(
                "{}: {}",
                rust_ident(&field.name.to_snake_case()),
                raw_field_expr(&field.ty, &format!("raw.{}", field.name.to_snake_case()))
            ));
        }
        for field in &variant.fields {
            fields.push(format!(
                "{}: {}",
                rust_ident(&field.name.to_snake_case()),
                raw_field_expr(
                    &field.ty,
                    &format!("raw.data.{payload}.{}", field.name.to_snake_case())
                )
            ));
        }
        let constructor = if fields.is_empty() {
            format!("Self::{}", variant.discriminant.to_upper_camel_case())
        } else {
            format!(
                "Self::{} {{ {} }}",
                variant.discriminant.to_upper_camel_case(),
                fields.join(", ")
            )
        };
        writeln!(
            out,
            "            cnativeapi::{} => {constructor},",
            c_event_variant(prefix, &group.name, &variant.discriminant)
        )
        .unwrap();
    }
    writeln!(out, "            _ => return None,").unwrap();
    writeln!(out, "        }})").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

/// Payload field type. A handle in an event is borrowed, so it surfaces as the
/// non-owning `XRef` rather than as an owned wrapper that would release it.
fn rust_event_field_type(ty: &TypeRef) -> String {
    match ty {
        TypeRef::Object { name, .. } => format!("{name}Ref"),
        other => rust_public_type(other),
    }
}

fn c_event_variant_field(discriminant: &str) -> String {
    codegen_shared::naming::c_event_variant_field(discriminant)
}

/// Reads one event payload field out of the raw struct.
fn raw_field_expr(ty: &TypeRef, access: &str) -> String {
    match ty {
        TypeRef::String | TypeRef::CString => format!(
            "if {access}.is_null() {{ None }} else {{ Some(CStr::from_ptr({access}).to_string_lossy().into_owned()) }}"
        ),
        // Borrowed: the C side frees the list when the callback returns.
        TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => format!(
            "if {access}.items.is_null() {{ Vec::new() }} else {{ (0..{access}.count as usize).filter_map(|index| {{ let ptr = *{access}.items.add(index); if ptr.is_null() {{ None }} else {{ Some(CStr::from_ptr(ptr).to_string_lossy().into_owned()) }} }}).collect() }}"
        ),
        TypeRef::Enum { name, .. } => format!("{name}::from_raw({access})"),
        TypeRef::Struct { name, .. } => format!("{name}::from_raw(&{access})"),
        // Borrowed for the duration of the callback only; see `XRef`.
        TypeRef::Object { name, .. } => format!("{name}Ref::from_raw({access})"),
        _ => access.to_string(),
    }
}

/// Listener registration for a class deriving from `EventEmitter<T>`.
fn render_rust_listener(out: &mut String, api: &Api, class: &Class, prefix: &str) {
    let Some(group) = emitted_group(api, class) else {
        return;
    };
    let raw_ty = format!("cnativeapi::{}", c_type_name(prefix, &group.name));
    let instance = class.is_instance();
    let receiver = if instance { "&self, " } else { "" };
    let self_arg = if instance { "self.handle, " } else { "" };

    writeln!(
        out,
        "    /// Registers `callback` for every `{}` this `{}` emits.",
        group.name, class.name
    )
    .unwrap();
    writeln!(out, "    ///").unwrap();
    writeln!(
        out,
        "    /// The closure is leaked: the C ABI takes a `user_data` pointer but"
    )
    .unwrap();
    writeln!(
        out,
        "    /// offers no hook to reclaim it, so removing the listener stops the"
    )
    .unwrap();
    writeln!(out, "    /// calls without freeing the closure.").unwrap();
    writeln!(
        out,
        "    pub fn add_listener({receiver}callback: impl Fn(&{}) + 'static) -> ListenerId {{",
        group.name
    )
    .unwrap();
    writeln!(
        out,
        "        unsafe extern \"C\" fn trampoline(event: *const {raw_ty}, user_data: *mut std::ffi::c_void) {{"
    )
    .unwrap();
    writeln!(
        out,
        "            if event.is_null() || user_data.is_null() {{"
    )
    .unwrap();
    writeln!(out, "                return;").unwrap();
    writeln!(out, "            }}").unwrap();
    writeln!(
        out,
        "            let callback = &*(user_data as *const Box<dyn Fn(&{})>);",
        group.name
    )
    .unwrap();
    writeln!(
        out,
        "            if let Some(event) = {}::from_raw(&*event) {{",
        group.name
    )
    .unwrap();
    writeln!(out, "                callback(&event);").unwrap();
    writeln!(out, "            }}").unwrap();
    writeln!(out, "        }}").unwrap();
    writeln!(
        out,
        "        let boxed: Box<Box<dyn Fn(&{})>> = Box::new(Box::new(callback));",
        group.name
    )
    .unwrap();
    writeln!(
        out,
        "        let user_data = Box::into_raw(boxed) as *mut std::ffi::c_void;"
    )
    .unwrap();
    writeln!(
        out,
        "        unsafe {{ cnativeapi::{}({self_arg}Some(trampoline), user_data) }}",
        c_add_listener_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out).unwrap();

    writeln!(
        out,
        "    /// Unregisters a listener. Returns false if unknown."
    )
    .unwrap();
    writeln!(
        out,
        "    pub fn remove_listener({receiver}listener_id: ListenerId) -> bool {{"
    )
    .unwrap();
    writeln!(
        out,
        "        unsafe {{ cnativeapi::{}({self_arg}listener_id) }}",
        c_remove_listener_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out).unwrap();
}

fn emitted_group<'a>(api: &'a Api, class: &Class) -> Option<&'a EventGroup> {
    let event = class.event.as_ref()?;
    api.headers
        .iter()
        .flat_map(|header| header.events.iter())
        .find(|group| &group.name == event)
}

// ---------------------------------------------------------------------------
// Handles
// ---------------------------------------------------------------------------

fn render_rust_handle_type(out: &mut String, class: &Class, prefix: &str) {
    let handle_ty = format!("cnativeapi::{}", c_type_name(prefix, &class.name));
    writeln!(out, "/// Owned handle to a native `{}`.", class.name).unwrap();
    writeln!(out, "#[derive(Debug)]").unwrap();
    writeln!(out, "pub struct {} {{", class.name).unwrap();
    writeln!(out, "    handle: {handle_ty},").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

fn render_rust_handle_helpers(out: &mut String, class: &Class, prefix: &str) {
    let handle_ty = format!("cnativeapi::{}", c_type_name(prefix, &class.name));
    writeln!(out, "    /// Adopts a handle returned by the C API.").unwrap();
    writeln!(out, "    ///").unwrap();
    writeln!(out, "    /// # Safety").unwrap();
    writeln!(
        out,
        "    /// `handle` must be a live handle that is not owned elsewhere."
    )
    .unwrap();
    writeln!(
        out,
        "    pub unsafe fn from_raw(handle: {handle_ty}) -> Option<Self> {{"
    )
    .unwrap();
    // A handle is a table index; zero is the "no object" sentinel.
    writeln!(out, "        if handle == 0 {{").unwrap();
    writeln!(out, "            None").unwrap();
    writeln!(out, "        }} else {{").unwrap();
    writeln!(out, "            Some(Self {{ handle }})").unwrap();
    writeln!(out, "        }}").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "    /// Borrows the underlying C handle.").unwrap();
    writeln!(out, "    pub fn as_raw(&self) -> {handle_ty} {{").unwrap();
    writeln!(out, "        self.handle").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out).unwrap();
}

/// A handle someone else owns. Event payloads hand these out: the C side
/// releases the handle as soon as the callback returns, so a value that ran
/// `Drop` would double-release it.
fn render_rust_borrowed_handle(out: &mut String, class: &Class, prefix: &str) {
    let handle_ty = format!("cnativeapi::{}", c_type_name(prefix, &class.name));
    let name = &class.name;
    writeln!(
        out,
        "/// A `{name}` owned elsewhere; using it does not release it."
    )
    .unwrap();
    writeln!(out, "#[derive(Debug, Clone, Copy, PartialEq, Eq)]").unwrap();
    writeln!(out, "pub struct {name}Ref({handle_ty});").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "impl {name}Ref {{").unwrap();
    writeln!(
        out,
        "    pub(crate) fn from_raw(handle: {handle_ty}) -> Self {{"
    )
    .unwrap();
    writeln!(out, "        Self(handle)").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "    pub fn as_raw(&self) -> {handle_ty} {{").unwrap();
    writeln!(out, "        self.0").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out).unwrap();
    writeln!(
        out,
        "    /// Runs `f` against the borrowed handle. The `{name}` it receives"
    )
    .unwrap();
    writeln!(out, "    /// must not outlive the call.").unwrap();
    writeln!(
        out,
        "    pub fn with<R>(&self, f: impl FnOnce(&{name}) -> R) -> R {{"
    )
    .unwrap();
    writeln!(
        out,
        "        let borrowed = std::mem::ManuallyDrop::new({name} {{ handle: self.0 }});"
    )
    .unwrap();
    writeln!(out, "        f(&borrowed)").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

fn render_rust_native_object(out: &mut String, class: &Class, prefix: &str) {
    writeln!(
        out,
        "    /// Platform-specific native object behind this handle."
    )
    .unwrap();
    writeln!(
        out,
        "    pub fn native_object(&self) -> *mut std::ffi::c_void {{"
    )
    .unwrap();
    writeln!(
        out,
        "        unsafe {{ cnativeapi::{}(self.handle) }}",
        c_native_object_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out).unwrap();
}

fn render_rust_drop(out: &mut String, class: &Class, prefix: &str) {
    writeln!(out, "impl Drop for {} {{", class.name).unwrap();
    writeln!(out, "    fn drop(&mut self) {{").unwrap();
    writeln!(out, "        if self.handle != 0 {{").unwrap();
    writeln!(
        out,
        "            unsafe {{ cnativeapi::{}(self.handle) }};",
        c_free_symbol(prefix, &class.name)
    )
    .unwrap();
    writeln!(out, "        }}").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    render_rust_borrowed_handle(out, class, prefix);
}

// ---------------------------------------------------------------------------
// Calls
// ---------------------------------------------------------------------------

fn render_rust_constructor(out: &mut String, class: &Class, ctor: &Constructor, prefix: &str) {
    let name = rust_constructor_name(class, ctor);
    let params = rust_param_list(&ctor.params);

    writeln!(
        out,
        "    /// Creates a new `{}`; returns `None` if the native side failed.",
        class.name
    )
    .unwrap();
    let safety = render_pointer_safety(out, &ctor.params);
    writeln!(
        out,
        "    pub {safety}fn {name}({}) -> Option<Self> {{",
        params.join(", ")
    )
    .unwrap();
    render_param_bindings(out, &ctor.params, "        ");
    writeln!(out, "        unsafe {{").unwrap();
    writeln!(
        out,
        "            Self::from_raw(cnativeapi::{}({}))",
        c_constructor_symbol(prefix, class, ctor),
        call_args(&ctor.params, None)
    )
    .unwrap();
    writeln!(out, "        }}").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out).unwrap();
}

fn render_rust_method(
    out: &mut String,
    class: &Class,
    method: &Method,
    header: &Header,
    prefix: &str,
) {
    let method_name = rust_method_name(class, method);
    let instance = class.is_instance() && !method.is_static;

    let mut params: Vec<String> = Vec::new();
    if instance {
        params.push("&self".to_string());
    }
    params.extend(rust_param_list(&method.params));

    let rust_return = rust_public_type(&method.return_type);
    let safety = render_pointer_safety(out, &method.params);
    if rust_return == "()" {
        writeln!(
            out,
            "    pub {safety}fn {method_name}({}) {{",
            params.join(", ")
        )
        .unwrap();
    } else {
        writeln!(
            out,
            "    pub {safety}fn {method_name}({}) -> {rust_return} {{",
            params.join(", ")
        )
        .unwrap();
    }

    render_param_bindings(out, &method.params, "        ");
    writeln!(out, "        unsafe {{").unwrap();

    let receiver = instance.then(|| "self.handle".to_string());
    let args = call_args(&method.params, receiver);
    let symbol = c_method_symbol(prefix, class, method);
    let ffi_fn = format!("cnativeapi::{symbol}");

    render_return(out, &method.return_type, &ffi_fn, &args, header, prefix);

    writeln!(out, "        }}").unwrap();
    writeln!(out, "    }}").unwrap();
    writeln!(out).unwrap();
}

fn render_pointer_safety(out: &mut String, params: &[Param]) -> &'static str {
    if !params
        .iter()
        .any(|param| rust_param_type(&param.ty).starts_with('*'))
    {
        return "";
    }
    writeln!(out, "    ///").unwrap();
    writeln!(out, "    /// # Safety").unwrap();
    writeln!(
        out,
        "    /// Raw pointers must reference valid platform objects of the expected type."
    )
    .unwrap();
    writeln!(
        out,
        "    /// The caller must uphold the native API's thread and lifetime requirements,"
    )
    .unwrap();
    writeln!(
        out,
        "    /// including keeping objects alive while the returned wrapper uses them."
    )
    .unwrap();
    "unsafe "
}

fn rust_param_list(params: &[Param]) -> Vec<String> {
    params
        .iter()
        .map(|param| {
            format!(
                "{}: {}",
                rust_ident(&param.name.to_snake_case()),
                rust_param_type(&param.ty)
            )
        })
        .collect()
}

/// Public Rust type for one parameter.
fn rust_param_type(ty: &TypeRef) -> String {
    match ty {
        TypeRef::String | TypeRef::CString => "&str".to_string(),
        // A shared_ptr parameter accepts None: that is how the C++ API clears
        // an icon or detaches a submenu.
        TypeRef::Object {
            name, shared: true, ..
        } => format!("Option<&{name}>"),
        TypeRef::Object { name, .. } => format!("&{name}"),
        TypeRef::Struct { name, .. } => format!("&{name}"),
        TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
            "&[String]".to_string()
        }
        TypeRef::Map { .. } => "&std::collections::HashMap<String, String>".to_string(),
        TypeRef::Callback { .. } => format!("impl Fn({}) + 'static", callback_signature(ty)),
        TypeRef::Optional { inner } => match inner.as_ref() {
            TypeRef::String | TypeRef::CString => "Option<&str>".to_string(),
            TypeRef::Object { name, .. } => format!("Option<&{name}>"),
            TypeRef::Struct { name, .. } => format!("Option<&{name}>"),
            TypeRef::Callback { .. } => {
                format!("Option<Box<dyn Fn({})>>", callback_signature(inner))
            }
            other => rust_param_type(other),
        },
        other => rust_public_type(other),
    }
}

/// Rust argument list of a callback, e.g. `u32` for `void(WindowId)`.
fn callback_signature(ty: &TypeRef) -> String {
    let TypeRef::Callback { params } = ty.unwrap_optional() else {
        return String::new();
    };
    params
        .iter()
        .map(|param| match param {
            TypeRef::Int { name } => rust_int_type(name),
            TypeRef::Alias { name, .. } => name.clone(),
            TypeRef::Bool => "bool".to_string(),
            other => rust_public_type(other),
        })
        .collect::<Vec<_>>()
        .join(", ")
}

/// Locals a call needs: owned CStrings, converted structs, boxed closures.
fn render_param_bindings(out: &mut String, params: &[Param], indent: &str) {
    for param in params {
        let name = rust_ident(&param.name.to_snake_case());
        match &param.ty {
            TypeRef::String | TypeRef::CString => {
                writeln!(
                    out,
                    "{indent}let {name}_native = CString::new({name}).expect(\"string argument contains interior nul byte\");"
                )
                .unwrap();
            }
            TypeRef::Struct { .. } => {
                writeln!(out, "{indent}let {name}_raw = {name}.to_raw();").unwrap();
            }
            TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
                writeln!(
                    out,
                    "{indent}let {name}_owned: Vec<CString> = {name}\n{indent}    .iter()\n{indent}    .map(|value| CString::new(value.as_str()).unwrap_or_default())\n{indent}    .collect();"
                )
                .unwrap();
                writeln!(
                    out,
                    "{indent}let mut {name}_ptrs: Vec<*mut std::os::raw::c_char> =\n{indent}    {name}_owned.iter().map(|value| value.as_ptr() as *mut _).collect();"
                )
                .unwrap();
                writeln!(
                    out,
                    "{indent}let {name}_native = cnativeapi::native_string_list_t {{\n{indent}    items: {name}_ptrs.as_mut_ptr(),\n{indent}    count: {name}_ptrs.len() as std::os::raw::c_long,\n{indent}}};"
                )
                .unwrap();
            }
            TypeRef::Map { .. } => {
                writeln!(
                    out,
                    "{indent}let {name}_keys: Vec<CString> = {name}.keys().map(|value| CString::new(value.as_str()).unwrap_or_default()).collect();"
                )
                .unwrap();
                writeln!(
                    out,
                    "{indent}let {name}_values: Vec<CString> = {name}.values().map(|value| CString::new(value.as_str()).unwrap_or_default()).collect();"
                )
                .unwrap();
                writeln!(
                    out,
                    "{indent}let mut {name}_key_ptrs: Vec<*mut std::os::raw::c_char> = {name}_keys.iter().map(|value| value.as_ptr() as *mut _).collect();"
                )
                .unwrap();
                writeln!(
                    out,
                    "{indent}let mut {name}_value_ptrs: Vec<*mut std::os::raw::c_char> = {name}_values.iter().map(|value| value.as_ptr() as *mut _).collect();"
                )
                .unwrap();
                writeln!(
                    out,
                    "{indent}let {name}_native = cnativeapi::native_string_map_t {{\n{indent}    keys: {name}_key_ptrs.as_mut_ptr(),\n{indent}    values: {name}_value_ptrs.as_mut_ptr(),\n{indent}    count: {name}_key_ptrs.len() as std::os::raw::c_long,\n{indent}}};"
                )
                .unwrap();
            }
            TypeRef::Callback { params: args } => {
                render_callback_trampoline(out, args, indent);
                writeln!(
                    out,
                    "{indent}let {name}_user_data = leak_callback(std::sync::Arc::new({name}));"
                )
                .unwrap();
            }
            TypeRef::Optional { inner } => match inner.as_ref() {
                TypeRef::String | TypeRef::CString => {
                    writeln!(
                        out,
                        "{indent}let {name}_native = {name}.map(|value| CString::new(value).expect(\"string argument contains interior nul byte\"));"
                    )
                    .unwrap();
                }
                TypeRef::Struct { .. } => {
                    writeln!(
                        out,
                        "{indent}let {name}_raw = {name}.map(|value| value.to_raw());"
                    )
                    .unwrap();
                }
                TypeRef::Callback { params: args } => {
                    render_callback_trampoline(out, args, indent);
                    writeln!(
                        out,
                        "{indent}let {name}_user_data = {name}\n{indent}    .map(|value| leak_callback(std::sync::Arc::from(value)))\n{indent}    .unwrap_or(std::ptr::null_mut());"
                    )
                    .unwrap();
                }
                _ => {}
            },
            _ => {}
        }
    }
}

/// Emits the `extern "C"` shim plus the leak helper a callback parameter needs.
/// Both are local to the enclosing function so their names never collide.
fn render_callback_trampoline(out: &mut String, params: &[TypeRef], indent: &str) {
    let signature = params
        .iter()
        .map(|param| match param {
            TypeRef::Int { name } => rust_int_type(name),
            TypeRef::Alias { underlying, .. } => rust_public_type(underlying),
            TypeRef::Bool => "bool".to_string(),
            other => rust_public_type(other),
        })
        .collect::<Vec<_>>();
    let args: Vec<String> = (0..params.len())
        .map(|index| format!("arg{index}"))
        .collect();
    let decl: Vec<String> = args
        .iter()
        .zip(signature.iter())
        .map(|(name, ty)| format!("{name}: {ty}"))
        .collect();

    writeln!(
        out,
        "{indent}unsafe extern \"C\" fn trampoline({}{}user_data: *mut std::ffi::c_void) {{",
        decl.join(", "),
        if decl.is_empty() { "" } else { ", " }
    )
    .unwrap();
    writeln!(out, "{indent}    if user_data.is_null() {{").unwrap();
    writeln!(out, "{indent}        return;").unwrap();
    writeln!(out, "{indent}    }}").unwrap();
    writeln!(
        out,
        "{indent}    let callback = &*(user_data as *const std::sync::Arc<dyn Fn({})>);",
        signature.join(", ")
    )
    .unwrap();
    writeln!(out, "{indent}    callback({});", args.join(", ")).unwrap();
    writeln!(out, "{indent}}}").unwrap();
    writeln!(
        out,
        "{indent}fn leak_callback(callback: std::sync::Arc<dyn Fn({})>) -> *mut std::ffi::c_void {{",
        signature.join(", ")
    )
    .unwrap();
    writeln!(
        out,
        "{indent}    // The C ABI keeps the pointer but offers no hook to reclaim it."
    )
    .unwrap();
    writeln!(
        out,
        "{indent}    Box::into_raw(Box::new(callback)) as *mut std::ffi::c_void"
    )
    .unwrap();
    writeln!(out, "{indent}}}").unwrap();
}

/// The C argument list, assuming `render_param_bindings` ran first.
fn call_args(params: &[Param], receiver: Option<String>) -> String {
    let mut args: Vec<String> = receiver.into_iter().collect();
    for param in params {
        let name = rust_ident(&param.name.to_snake_case());
        match &param.ty {
            TypeRef::String | TypeRef::CString => args.push(format!("{name}_native.as_ptr()")),
            TypeRef::Object { shared: true, .. } => {
                args.push(format!("{name}.map_or(0, |value| value.as_raw())"))
            }
            TypeRef::Object { .. } => args.push(format!("{name}.as_raw()")),
            TypeRef::Struct { .. } => args.push(format!("{name}_raw.raw")),
            TypeRef::Enum { .. } => args.push(format!("{name}.to_raw()")),
            TypeRef::Vector { .. } | TypeRef::Map { .. } => args.push(format!("{name}_native")),
            // A callback occupies two C parameters.
            TypeRef::Callback { .. } => {
                args.push("Some(trampoline)".to_string());
                args.push(format!("{name}_user_data"));
            }
            TypeRef::Optional { inner } => match inner.as_ref() {
                TypeRef::String | TypeRef::CString => args.push(format!(
                    "{name}_native.as_ref().map_or(std::ptr::null(), |value| value.as_ptr())"
                )),
                TypeRef::Object { .. } => {
                    args.push(format!("{name}.map_or(0, |value| value.as_raw())"))
                }
                TypeRef::Struct { .. } => args.push(format!(
                    "{name}_raw.as_ref().map_or(std::ptr::null(), |value| &value.raw as *const _)"
                )),
                TypeRef::Callback { .. } => {
                    args.push(format!(
                        "if {name}_user_data.is_null() {{ None }} else {{ Some(trampoline) }}"
                    ));
                    args.push(format!("{name}_user_data"));
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
    ffi_fn: &str,
    args: &str,
    header: &Header,
    prefix: &str,
) {
    match ty {
        TypeRef::Void => {
            writeln!(out, "            {ffi_fn}({args});").unwrap();
        }
        TypeRef::Struct { name, .. } => {
            let owns_memory = header
                .structs
                .iter()
                .any(|item| item.name == *name && struct_has_owned_fields(item));
            if owns_memory {
                writeln!(out, "            let mut raw = {ffi_fn}({args});").unwrap();
                writeln!(out, "            let result = {name}::from_raw(&raw);").unwrap();
                writeln!(
                    out,
                    "            cnativeapi::{}(&mut raw);",
                    c_free_symbol(prefix, name)
                )
                .unwrap();
                writeln!(out, "            result").unwrap();
            } else {
                writeln!(out, "            let raw = {ffi_fn}({args});").unwrap();
                writeln!(out, "            {name}::from_raw(&raw)").unwrap();
            }
        }
        TypeRef::Enum { name, .. } => {
            writeln!(out, "            {name}::from_raw({ffi_fn}({args}))").unwrap();
        }
        TypeRef::String | TypeRef::CString => {
            writeln!(out, "            let ptr = {ffi_fn}({args});").unwrap();
            writeln!(out, "            if ptr.is_null() {{").unwrap();
            writeln!(out, "                return None;").unwrap();
            writeln!(out, "            }}").unwrap();
            writeln!(
                out,
                "            let value = CStr::from_ptr(ptr).to_string_lossy().into_owned();"
            )
            .unwrap();
            writeln!(out, "            cnativeapi::{STRING_FREE_FN}(ptr);").unwrap();
            writeln!(out, "            Some(value)").unwrap();
        }
        TypeRef::Object { name, .. } => {
            writeln!(out, "            {name}::from_raw({ffi_fn}({args}))").unwrap();
        }
        TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
            writeln!(out, "            let mut list = {ffi_fn}({args});").unwrap();
            writeln!(out, "            let mut items = Vec::new();").unwrap();
            writeln!(out, "            if !list.items.is_null() {{").unwrap();
            writeln!(
                out,
                "                for index in 0..list.count as isize {{"
            )
            .unwrap();
            writeln!(
                out,
                "                    let ptr = *list.items.offset(index);"
            )
            .unwrap();
            writeln!(out, "                    if !ptr.is_null() {{").unwrap();
            writeln!(out, "                        items.push(CStr::from_ptr(ptr).to_string_lossy().into_owned());").unwrap();
            writeln!(out, "                    }}").unwrap();
            writeln!(out, "                }}").unwrap();
            writeln!(out, "            }}").unwrap();
            writeln!(
                out,
                "            cnativeapi::{STRING_LIST_FREE_FN}(&mut list);"
            )
            .unwrap();
            writeln!(out, "            items").unwrap();
        }
        TypeRef::Vector { element } => {
            render_rust_list_return(out, element, prefix, ffi_fn, args);
        }
        TypeRef::Map { .. } => {
            writeln!(out, "            let mut raw = {ffi_fn}({args});").unwrap();
            writeln!(
                out,
                "            let mut entries = std::collections::HashMap::new();"
            )
            .unwrap();
            writeln!(
                out,
                "            if !raw.keys.is_null() && !raw.values.is_null() {{"
            )
            .unwrap();
            writeln!(out, "                for index in 0..raw.count as isize {{").unwrap();
            writeln!(
                out,
                "                    let key = *raw.keys.offset(index);"
            )
            .unwrap();
            writeln!(
                out,
                "                    let value = *raw.values.offset(index);"
            )
            .unwrap();
            writeln!(out, "                    if key.is_null() {{").unwrap();
            writeln!(out, "                        continue;").unwrap();
            writeln!(out, "                    }}").unwrap();
            writeln!(out, "                    entries.insert(").unwrap();
            writeln!(
                out,
                "                        CStr::from_ptr(key).to_string_lossy().into_owned(),"
            )
            .unwrap();
            writeln!(out, "                        if value.is_null() {{ String::new() }} else {{ CStr::from_ptr(value).to_string_lossy().into_owned() }},").unwrap();
            writeln!(out, "                    );").unwrap();
            writeln!(out, "                }}").unwrap();
            writeln!(out, "            }}").unwrap();
            writeln!(
                out,
                "            cnativeapi::{STRING_MAP_FREE_FN}(&mut raw);"
            )
            .unwrap();
            writeln!(out, "            entries").unwrap();
        }
        TypeRef::Optional { inner } => render_return(out, inner, ffi_fn, args, header, prefix),
        _ => {
            writeln!(out, "            {ffi_fn}({args})").unwrap();
        }
    }
}

fn render_rust_list_return(
    out: &mut String,
    element: &TypeRef,
    prefix: &str,
    ffi_fn: &str,
    args: &str,
) {
    let name = match element {
        TypeRef::Object { name, .. } => name,
        _ => return,
    };
    let field = c_list_field(name);
    writeln!(out, "            let mut list = {ffi_fn}({args});").unwrap();
    writeln!(out, "            let mut items = Vec::new();").unwrap();
    writeln!(out, "            if !list.{field}.is_null() {{").unwrap();
    writeln!(
        out,
        "                for index in 0..list.count as isize {{"
    )
    .unwrap();
    writeln!(
        out,
        "                    if let Some(item) = {name}::from_raw(*list.{field}.offset(index)) {{"
    )
    .unwrap();
    writeln!(out, "                        items.push(item);").unwrap();
    writeln!(out, "                    }}").unwrap();
    writeln!(out, "                }}").unwrap();
    writeln!(out, "            }}").unwrap();
    writeln!(
        out,
        "            // Handles are now owned by `items`; drop just the array."
    )
    .unwrap();
    writeln!(
        out,
        "            cnativeapi::{}(&mut list);",
        c_list_release_symbol(prefix, name)
    )
    .unwrap();
    writeln!(out, "            items").unwrap();
}

fn is_callback(ty: &TypeRef) -> bool {
    codegen_shared::naming::is_callback(ty)
}

fn _unused(_: &Field) {}
