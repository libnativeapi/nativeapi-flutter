//! JavaScript / TypeScript binding: a Node-API addon plus a TypeScript layer.
//!
//! Two outputs per header, mirroring the raw/public split of the C# binding:
//!
//! - `src/generated/<stem>.cc` — N-API glue. One JS function per C symbol,
//!   exported under the C symbol's own name, converting JS values to C
//!   arguments and C results back to plain JS data (structs become objects,
//!   handles become `bigint`s, owned strings and lists are copied and freed).
//! - `lib/<stem>.ts` — the public API: enums, struct interfaces, event unions,
//!   and classes wrapping handles, built on the raw functions above.
//!
//! Shared across headers: `src/generated/types.h` (struct and event converters,
//! used by every glue file) and `src/generated/modules.cc` (registration), plus
//! the `lib/modules.ts` barrel. The runtime both sides lean on —
//! `src/napi_support.h`, `src/event_loop_*`, `lib/runtime.ts` — is hand-written.
//!
//! The TypeScript uses erasable syntax only (no `enum`, no parameter
//! properties), so Node's type stripping, Deno and Bun run it without a build.

use std::fmt::Write;
use std::path::Path;

use heck::{ToLowerCamelCase, ToSnakeCase, ToUpperCamelCase};

use codegen_shared::ir::{Api, Class, EventGroup, Header, Method, Param, Struct, TypeRef};
use codegen_shared::naming::{
    c_add_listener_symbol, c_constructor_symbol, c_event_variant, c_event_variant_field,
    c_free_symbol, c_list_field, c_list_release_symbol, c_method_symbol, c_native_object_symbol,
    c_param_type, c_release_user_data_param, c_remove_listener_symbol, c_type_name,
    c_user_data_param, constructor_suffix,
    is_binding_accessor, struct_has_owned_fields, swift_method_name, TypeOrigins, STRING_FREE_FN,
    STRING_LIST_FREE_FN, STRING_MAP_FREE_FN,
};
use codegen_shared::GeneratedFile;

const BANNER: &str = "// AUTO-GENERATED. DO NOT EDIT.\n\
// Any manual changes WILL BE LOST when this file is regenerated.\n";

/// `Application::Run` blocks in the platform loop, which would starve the JS
/// event loop for the life of the app. The TypeScript layer replaces these
/// symbols with the pumped loop in `lib/runtime.ts`; see `render_loop_method`.
const LOOP_RUN: &str = "native_application_run";
const LOOP_RUN_WITH_WINDOW: &str = "native_application_run_with_window";
const LOOP_QUIT: &str = "native_application_quit";

/// Classes that are plain data, touching no platform object. Their calls run
/// on the JS thread even where every other call hops to the UI thread (see
/// `OnMainThread` in src/napi_support.h), which matters for code that feeds
/// them in bulk — a shape morph adds a thousand points per frame. Struct
/// methods (`Color.fromHex`) never hop either.
const THREAD_FREE_CLASSES: &[&str] = &["WindowShape", "WindowShadow"];

// ---------------------------------------------------------------------------
// Entry points
// ---------------------------------------------------------------------------

/// The glue and TypeScript files for one header.
pub fn generate(
    api: &Api,
    header: &Header,
    origins: &TypeOrigins,
    js_root: &Path,
    prefix: &str,
) -> Vec<GeneratedFile> {
    vec![
        GeneratedFile {
            path: js_root
                .join("src")
                .join("generated")
                .join(format!("{}.cc", header.stem)),
            contents: glue_file(api, header, prefix),
        },
        GeneratedFile {
            path: js_root.join("lib").join(format!("{}.ts", header.stem)),
            contents: ts_file(api, header, origins, prefix),
        },
    ]
}

/// Files spanning every header: converters, registration, TypeScript barrel.
pub fn generate_shared(api: &Api, js_root: &Path, prefix: &str) -> Vec<GeneratedFile> {
    vec![
        GeneratedFile {
            path: js_root.join("src").join("generated").join("types.h"),
            contents: types_header(api, prefix),
        },
        GeneratedFile {
            path: js_root.join("src").join("generated").join("modules.cc"),
            contents: modules_cc(api),
        },
        GeneratedFile {
            path: js_root.join("lib").join("modules.ts"),
            contents: modules_ts(api),
        },
    ]
}

fn modules_cc(api: &Api) -> String {
    let mut out = String::from(BANNER);
    out.push('\n');
    writeln!(out, "#include \"../napi_support.h\"").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "namespace nativeapi_js {{").unwrap();
    writeln!(out).unwrap();
    for header in &api.headers {
        writeln!(
            out,
            "void {}(napi_env env, napi_value exports);",
            register_fn(header)
        )
        .unwrap();
    }
    writeln!(out).unwrap();
    writeln!(
        out,
        "void RegisterGenerated(napi_env env, napi_value exports) {{"
    )
    .unwrap();
    for header in &api.headers {
        writeln!(out, "  {}(env, exports);", register_fn(header)).unwrap();
    }
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "}}  // namespace nativeapi_js").unwrap();
    out
}

fn modules_ts(api: &Api) -> String {
    let mut out = String::from(BANNER);
    out.push('\n');
    for header in &api.headers {
        writeln!(out, "export * from \"./{}.ts\";", header.stem).unwrap();
    }
    out
}

fn register_fn(header: &Header) -> String {
    format!("Register{}", header.stem.to_upper_camel_case())
}

// ---------------------------------------------------------------------------
// types.h: converters shared by every glue file
// ---------------------------------------------------------------------------

fn types_header(api: &Api, prefix: &str) -> String {
    let mut out = String::from(BANNER);
    out.push('\n');
    writeln!(out, "#pragma once").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "#include \"../napi_support.h\"").unwrap();
    writeln!(out).unwrap();
    for header in &api.headers {
        writeln!(out, "#include \"capi/{}_c.h\"", header.stem).unwrap();
    }
    writeln!(out).unwrap();
    writeln!(out, "namespace nativeapi_js {{").unwrap();
    writeln!(out).unwrap();

    // Declarations first: converters call each other across headers.
    for header in &api.headers {
        for item in &header.structs {
            let c_ty = c_type_name(prefix, &item.name);
            writeln!(out, "inline Value ToValue(const {c_ty}& value);").unwrap();
            writeln!(
                out,
                "inline bool FromJs(napi_env env, napi_value value, {c_ty}* out, Arena& arena);"
            )
            .unwrap();
        }
        for group in &header.events {
            let c_ty = c_type_name(prefix, &group.name);
            writeln!(out, "inline Value ToValue(const {c_ty}& event);").unwrap();
        }
    }
    writeln!(out).unwrap();

    for header in &api.headers {
        for item in &header.structs {
            render_struct_converters(&mut out, item, prefix);
        }
        for group in &header.events {
            render_event_converter(&mut out, group, prefix);
        }
    }

    writeln!(out, "}}  // namespace nativeapi_js").unwrap();
    out
}

fn render_struct_converters(out: &mut String, item: &Struct, prefix: &str) {
    let c_ty = c_type_name(prefix, &item.name);

    writeln!(out, "inline Value ToValue(const {c_ty}& value) {{").unwrap();
    writeln!(out, "  Value result = Value::Object();").unwrap();
    for field in &item.fields {
        if matches!(field.ty.unwrap_optional(), TypeRef::Callback { .. }) {
            continue;
        }
        let access = format!("value.{}", field.name.to_snake_case());
        writeln!(
            out,
            "  result.Set(\"{}\", {});",
            js_field(&field.name),
            value_expr(&field.ty, &access)
        )
        .unwrap();
    }
    writeln!(out, "  return result;").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    // Missing properties keep the zero value, so a partial object literal is a
    // valid argument; wrong types still throw.
    writeln!(
        out,
        "inline bool FromJs(napi_env env, napi_value value, {c_ty}* out, Arena& arena) {{"
    )
    .unwrap();
    writeln!(
        out,
        "  if (!ExpectObject(env, value, \"{}\")) {{",
        item.name
    )
    .unwrap();
    writeln!(out, "    return false;").unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out, "  napi_value field = nullptr;").unwrap();
    for field in &item.fields {
        let raw = field.name.to_snake_case();
        writeln!(
            out,
            "  if (!GetField(env, value, \"{}\", &field)) {{",
            js_field(&field.name)
        )
        .unwrap();
        writeln!(out, "    return false;").unwrap();
        writeln!(out, "  }}").unwrap();
        writeln!(out, "  if (field != nullptr) {{").unwrap();
        match field.ty.unwrap_optional() {
            TypeRef::Callback { params } => {
                let user_data = c_user_data_param(&field.name);
                writeln!(out, "    Callback* callback = nullptr;").unwrap();
                writeln!(
                    out,
                    "    if (!GetCallback(env, field, /*optional=*/true, &callback)) {{"
                )
                .unwrap();
                writeln!(out, "      return false;").unwrap();
                writeln!(out, "    }}").unwrap();
                writeln!(
                    out,
                    "    out->{raw} = callback ? {} : nullptr;",
                    trampoline(params, prefix)
                )
                .unwrap();
                writeln!(out, "    out->{user_data} = callback;").unwrap();
                writeln!(
                    out,
                    "    out->{} = &Callback::ReleaseUserData;",
                    c_release_user_data_param(&field.name)
                )
                .unwrap();
            }
            other => {
                let read = read_into(other, "field", &format!("&out->{raw}"));
                writeln!(out, "    if (!{read}) {{").unwrap();
                writeln!(out, "      return false;").unwrap();
                writeln!(out, "    }}").unwrap();
            }
        }
        writeln!(out, "  }}").unwrap();
    }
    writeln!(out, "  return true;").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

fn render_event_converter(out: &mut String, group: &EventGroup, prefix: &str) {
    let c_ty = c_type_name(prefix, &group.name);
    writeln!(out, "inline Value ToValue(const {c_ty}& event) {{").unwrap();
    writeln!(out, "  Value result = Value::Object();").unwrap();
    writeln!(out, "  switch (event.type) {{").unwrap();
    for variant in &group.variants {
        writeln!(
            out,
            "    case {}:",
            c_event_variant(prefix, &group.name, &variant.discriminant)
        )
        .unwrap();
        writeln!(
            out,
            "      result.Set(\"type\", Value::String(\"{}\"));",
            event_tag(&variant.discriminant)
        )
        .unwrap();
        let payload = c_event_variant_field(&variant.discriminant);
        for field in &variant.fields {
            let access = format!("event.data.{payload}.{}", field.name.to_snake_case());
            writeln!(
                out,
                "      result.Set(\"{}\", {});",
                js_field(&field.name),
                value_expr(&field.ty, &access)
            )
            .unwrap();
        }
        writeln!(out, "      break;").unwrap();
    }
    writeln!(out, "    default:").unwrap();
    writeln!(out, "      return Value::Null();").unwrap();
    writeln!(out, "  }}").unwrap();
    for field in &group.common {
        let access = format!("event.{}", field.name.to_snake_case());
        writeln!(
            out,
            "  result.Set(\"{}\", {});",
            js_field(&field.name),
            value_expr(&field.ty, &access)
        )
        .unwrap();
    }
    writeln!(out, "  return result;").unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

/// A C value (struct field, event field, callback argument) as a `Value`.
/// Everything is copied: the C side may free it as soon as we return.
fn value_expr(ty: &TypeRef, access: &str) -> String {
    match ty.unwrap_optional() {
        TypeRef::Bool => format!("Value::Bool({access})"),
        TypeRef::Int { .. }
        | TypeRef::Float { .. }
        | TypeRef::Enum { .. }
        | TypeRef::Alias { .. } => {
            format!("Value::Number(static_cast<double>({access}))")
        }
        TypeRef::String | TypeRef::CString => format!("Value::String({access})"),
        TypeRef::Struct { .. } => format!("ToValue({access})"),
        // A borrowed handle: valid for the duration of the callback only.
        TypeRef::Object { .. } => format!("Value::BigInt({access})"),
        TypeRef::Vector { element } if matches!(element.as_ref(), TypeRef::String) => {
            format!("CopyStringList({access})")
        }
        TypeRef::Map { .. } => format!("CopyStringMap({access})"),
        TypeRef::RawPointer => format!("Value::BigInt(reinterpret_cast<uintptr_t>({access}))"),
        _ => "Value::Undefined()".to_string(),
    }
}

/// A call reading JS value `js` into the C lvalue behind pointer `target`.
fn read_into(ty: &TypeRef, js: &str, target: &str) -> String {
    match ty {
        TypeRef::Bool => format!("GetBool(env, {js}, {target})"),
        TypeRef::Int { .. }
        | TypeRef::Float { .. }
        | TypeRef::Enum { .. }
        | TypeRef::Alias { .. } => {
            format!("GetNumber(env, {js}, {target})")
        }
        TypeRef::String | TypeRef::CString => format!("GetString(env, {js}, arena, {target})"),
        TypeRef::Struct { .. } => format!("FromJs(env, {js}, {target}, arena)"),
        TypeRef::Object { .. } => format!("GetHandle(env, {js}, {target})"),
        TypeRef::Vector { .. } => format!("GetStringList(env, {js}, arena, {target})"),
        TypeRef::Map { .. } => format!("GetStringMap(env, {js}, arena, {target})"),
        TypeRef::RawPointer => format!("GetPointer(env, {js}, {target})"),
        TypeRef::Optional { inner } => match inner.as_ref() {
            TypeRef::String | TypeRef::CString => {
                format!("GetOptionalString(env, {js}, arena, {target})")
            }
            other => read_into(other, js, target),
        },
        _ => "false".to_string(),
    }
}

/// A captureless lambda with the exact C callback signature, forwarding its
/// arguments to the `Callback` in `user_data`. Unary `+` decays it to the
/// function pointer, so it can sit in a conditional against `nullptr`.
fn trampoline(params: &[TypeRef], prefix: &str) -> String {
    let mut decl: Vec<String> = params
        .iter()
        .enumerate()
        .map(|(index, ty)| format!("{} arg{index}", c_param_type(ty, prefix)))
        .collect();
    decl.push("void* user_data".to_string());
    let args: Vec<String> = params
        .iter()
        .enumerate()
        .map(|(index, ty)| value_expr(ty, &format!("arg{index}")))
        .collect();
    format!(
        "+[]({}) {{ Callback::Dispatch(user_data, {{{}}}); }}",
        decl.join(", "),
        args.join(", ")
    )
}

// ---------------------------------------------------------------------------
// <stem>.cc: one N-API function per C symbol
// ---------------------------------------------------------------------------

struct Glue<'a> {
    api: &'a Api,
    prefix: &'a str,
    out: String,
    exports: Vec<String>,
    /// Whether the functions being emitted run their C call on the UI thread.
    hop: bool,
}

fn glue_file(api: &Api, header: &Header, prefix: &str) -> String {
    let mut glue = Glue {
        api,
        prefix,
        out: String::new(),
        exports: Vec::new(),
        hop: true,
    };

    for item in &header.structs {
        glue.struct_members(item);
    }
    for class in &header.classes {
        glue.class(class);
    }

    let mut out = String::from(BANNER);
    out.push('\n');
    writeln!(out, "#include \"types.h\"").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "namespace nativeapi_js {{").unwrap();
    if !glue.out.is_empty() {
        writeln!(out, "namespace {{").unwrap();
        writeln!(out).unwrap();
        out.push_str(&glue.out);
        writeln!(out, "}}  // namespace").unwrap();
    }
    writeln!(out).unwrap();
    writeln!(
        out,
        "void {}(napi_env env, napi_value exports) {{",
        register_fn(header)
    )
    .unwrap();
    for item in &header.structs {
        for constant in &item.constants {
            let symbol = c_struct_constant(prefix, &item.name, constant);
            writeln!(
                out,
                "  ExportValue(env, exports, \"{symbol}\", ToValue({symbol}));"
            )
            .unwrap();
        }
    }
    for symbol in &glue.exports {
        writeln!(out, "  Export(env, exports, \"{symbol}\", Js_{symbol});").unwrap();
    }
    if glue.exports.is_empty() && header.structs.iter().all(|s| s.constants.is_empty()) {
        writeln!(out, "  (void)env;").unwrap();
        writeln!(out, "  (void)exports;").unwrap();
    }
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
    writeln!(out, "}}  // namespace nativeapi_js").unwrap();
    out
}

impl Glue<'_> {
    fn struct_members(&mut self, item: &Struct) {
        self.hop = false;
        let c_ty = c_type_name(self.prefix, &item.name);
        for method in &item.methods {
            let symbol = c_struct_method_symbol(self.prefix, item, method);
            let receiver = (!method.is_static).then(|| Receiver::Value(c_ty.clone()));
            self.function(&symbol, receiver, &method.params, &method.return_type);
        }
    }

    fn class(&mut self, class: &Class) {
        self.hop = !THREAD_FREE_CLASSES.contains(&class.name.as_str());
        let prefix = self.prefix;
        let self_receiver = || Receiver::Handle;
        if class.is_instance() {
            let object = TypeRef::Object {
                name: class.name.clone(),
                qualified_name: class.qualified_name.clone(),
                shared: false,
            };
            for ctor in &class.constructors {
                let symbol = c_constructor_symbol(prefix, class, ctor);
                self.function(&symbol, None, &ctor.params, &object);
            }
            let free = c_free_symbol(prefix, &class.name);
            self.function(&free, Some(self_receiver()), &[], &TypeRef::Void);
            if class.native_object {
                let symbol = c_native_object_symbol(prefix, &class.name);
                self.function(&symbol, Some(self_receiver()), &[], &TypeRef::RawPointer);
            }
        }
        for method in &class.methods {
            let symbol = c_method_symbol(prefix, class, method);
            let receiver = (class.is_instance() && !method.is_static).then(self_receiver);
            self.function(&symbol, receiver, &method.params, &method.return_type);
        }
        if let Some(group) = emitted_group(self.api, class) {
            self.listener(class, group);
        }
    }

    fn function(
        &mut self,
        symbol: &str,
        receiver: Option<Receiver>,
        params: &[Param],
        return_type: &TypeRef,
    ) {
        let out = &mut self.out;
        writeln!(
            out,
            "napi_value Js_{symbol}(napi_env env, napi_callback_info info) {{"
        )
        .unwrap();
        writeln!(out, "  Args args(env, info);").unwrap();
        writeln!(out, "  if (!args.ok()) {{").unwrap();
        writeln!(out, "    return nullptr;").unwrap();
        writeln!(out, "  }}").unwrap();
        writeln!(out, "  Arena arena;").unwrap();
        writeln!(out, "  (void)arena;").unwrap();

        let mut call_args = Vec::new();
        let mut index = 0usize;
        match &receiver {
            Some(Receiver::Handle) => {
                writeln!(out, "  uint64_t self = 0;").unwrap();
                writeln!(out, "  if (!GetHandle(env, args[0], &self)) {{").unwrap();
                writeln!(out, "    return nullptr;").unwrap();
                writeln!(out, "  }}").unwrap();
                call_args.push("self".to_string());
                index = 1;
            }
            Some(Receiver::Value(c_ty)) => {
                writeln!(out, "  {c_ty} self = {{}};").unwrap();
                writeln!(out, "  if (!FromJs(env, args[0], &self, arena)) {{").unwrap();
                writeln!(out, "    return nullptr;").unwrap();
                writeln!(out, "  }}").unwrap();
                call_args.push("self".to_string());
                index = 1;
            }
            None => {}
        }

        for (offset, param) in params.iter().enumerate() {
            let js = format!("args[{}]", index + offset);
            let local = format!("p{offset}");
            render_param(out, self.prefix, param, &js, &local, &mut call_args);
        }

        let call = if self.hop {
            format!(
                "OnMainThread([&] {{ return {symbol}({}); }})",
                call_args.join(", ")
            )
        } else {
            format!("{symbol}({})", call_args.join(", "))
        };
        if matches!(return_type, TypeRef::Void) {
            writeln!(out, "  {call};").unwrap();
            writeln!(out, "  return Undefined(env);").unwrap();
        } else {
            writeln!(out, "  auto result = {call};").unwrap();
            render_return(out, self.api, self.prefix, return_type);
        }
        writeln!(out, "}}").unwrap();
        writeln!(out).unwrap();
        self.exports.push(symbol.to_string());
    }

    fn listener(&mut self, class: &Class, group: &EventGroup) {
        let prefix = self.prefix;
        let add = c_add_listener_symbol(prefix, &class.name);
        let remove = c_remove_listener_symbol(prefix, &class.name);
        let event_ty = c_type_name(prefix, &group.name);
        let instance = class.is_instance();
        let out = &mut self.out;

        writeln!(
            out,
            "napi_value Js_{add}(napi_env env, napi_callback_info info) {{"
        )
        .unwrap();
        writeln!(out, "  Args args(env, info);").unwrap();
        writeln!(out, "  if (!args.ok()) {{").unwrap();
        writeln!(out, "    return nullptr;").unwrap();
        writeln!(out, "  }}").unwrap();
        writeln!(out, "  uint64_t self = 0;").unwrap();
        let callback_index = if instance {
            writeln!(out, "  if (!GetHandle(env, args[0], &self)) {{").unwrap();
            writeln!(out, "    return nullptr;").unwrap();
            writeln!(out, "  }}").unwrap();
            1
        } else {
            0
        };
        writeln!(out, "  Callback* callback = nullptr;").unwrap();
        writeln!(
            out,
            "  if (!GetCallback(env, args[{callback_index}], /*optional=*/false, &callback)) {{"
        )
        .unwrap();
        writeln!(out, "    return nullptr;").unwrap();
        writeln!(out, "  }}").unwrap();
        let self_arg = if instance { "self, " } else { "" };
        writeln!(
            out,
            "  native_listener_id_t id = OnMainThread([&] {{ return {add}({self_arg}+[](const {event_ty}* event, void* user_data) {{"
        )
        .unwrap();
        writeln!(out, "    if (event != nullptr) {{").unwrap();
        writeln!(
            out,
            "      Callback::Dispatch(user_data, {{ToValue(*event)}});"
        )
        .unwrap();
        writeln!(out, "    }}").unwrap();
        // The core releases `callback` once the listener is removed, its
        // emitter destroyed, or registration failed.
        writeln!(out, "  }}, callback, &Callback::ReleaseUserData); }});").unwrap();
        writeln!(
            out,
            "  return Value::Number(static_cast<double>(id)).ToJs(env);"
        )
        .unwrap();
        writeln!(out, "}}").unwrap();
        writeln!(out).unwrap();

        writeln!(
            out,
            "napi_value Js_{remove}(napi_env env, napi_callback_info info) {{"
        )
        .unwrap();
        writeln!(out, "  Args args(env, info);").unwrap();
        writeln!(out, "  if (!args.ok()) {{").unwrap();
        writeln!(out, "    return nullptr;").unwrap();
        writeln!(out, "  }}").unwrap();
        writeln!(out, "  uint64_t self = 0;").unwrap();
        let id_index = if instance {
            writeln!(out, "  if (!GetHandle(env, args[0], &self)) {{").unwrap();
            writeln!(out, "    return nullptr;").unwrap();
            writeln!(out, "  }}").unwrap();
            1
        } else {
            0
        };
        writeln!(out, "  native_listener_id_t id = 0;").unwrap();
        writeln!(out, "  if (!GetNumber(env, args[{id_index}], &id)) {{").unwrap();
        writeln!(out, "    return nullptr;").unwrap();
        writeln!(out, "  }}").unwrap();
        writeln!(
            out,
            "  bool removed = OnMainThread([&] {{ return {remove}({self_arg}id); }});"
        )
        .unwrap();
        writeln!(out, "  return Value::Bool(removed).ToJs(env);").unwrap();
        writeln!(out, "}}").unwrap();
        writeln!(out).unwrap();

        self.exports.push(add);
        self.exports.push(remove);
    }
}

enum Receiver {
    /// An instance method: the first JS argument is the object's handle.
    Handle,
    /// A struct method: the first JS argument is the struct value itself.
    Value(String),
}

fn render_param(
    out: &mut String,
    prefix: &str,
    param: &Param,
    js: &str,
    local: &str,
    call_args: &mut Vec<String>,
) {
    let bail = |out: &mut String, read: String| {
        writeln!(out, "  if (!{read}) {{").unwrap();
        writeln!(out, "    return nullptr;").unwrap();
        writeln!(out, "  }}").unwrap();
    };
    match &param.ty {
        TypeRef::Callback { params } => {
            writeln!(out, "  Callback* {local} = nullptr;").unwrap();
            bail(
                out,
                format!("GetCallback(env, {js}, /*optional=*/false, &{local})"),
            );
            call_args.push(trampoline(params, prefix));
            call_args.push(local.to_string());
            call_args.push("&Callback::ReleaseUserData".to_string());
        }
        TypeRef::Optional { inner } if matches!(inner.as_ref(), TypeRef::Callback { .. }) => {
            let TypeRef::Callback { params } = inner.as_ref() else {
                unreachable!()
            };
            writeln!(out, "  Callback* {local} = nullptr;").unwrap();
            bail(
                out,
                format!("GetCallback(env, {js}, /*optional=*/true, &{local})"),
            );
            call_args.push(format!(
                "{local} ? {} : nullptr",
                trampoline(params, prefix)
            ));
            call_args.push(local.to_string());
            call_args.push("&Callback::ReleaseUserData".to_string());
        }
        TypeRef::Optional { inner } if matches!(inner.as_ref(), TypeRef::Struct { .. }) => {
            let TypeRef::Struct { name, .. } = inner.as_ref() else {
                unreachable!()
            };
            let c_ty = c_type_name(prefix, name);
            writeln!(out, "  {c_ty} {local}_value = {{}};").unwrap();
            writeln!(out, "  const {c_ty}* {local} = nullptr;").unwrap();
            writeln!(out, "  if (!IsNullish(env, {js})) {{").unwrap();
            writeln!(out, "    if (!FromJs(env, {js}, &{local}_value, arena)) {{").unwrap();
            writeln!(out, "      return nullptr;").unwrap();
            writeln!(out, "    }}").unwrap();
            writeln!(out, "    {local} = &{local}_value;").unwrap();
            writeln!(out, "  }}").unwrap();
            call_args.push(local.to_string());
        }
        other => {
            writeln!(out, "  {} {local} = {{}};", c_param_type(other, prefix)).unwrap();
            bail(out, read_into(other, js, &format!("&{local}")));
            call_args.push(local.to_string());
        }
    }
}

fn render_return(out: &mut String, api: &Api, prefix: &str, ty: &TypeRef) {
    match ty {
        TypeRef::Void => writeln!(out, "  return Undefined(env);").unwrap(),
        TypeRef::String | TypeRef::CString => {
            // A plain string result is never absent in C++; null here only
            // means the handle was invalid, which reads best as "".
            writeln!(
                out,
                "  Value value = Value::String(result ? result : \"\");"
            )
            .unwrap();
            writeln!(out, "  {STRING_FREE_FN}(result);").unwrap();
            writeln!(out, "  return value.ToJs(env);").unwrap();
        }
        TypeRef::Optional { inner } if matches!(inner.as_ref(), TypeRef::String) => {
            writeln!(out, "  Value value = Value::String(result);").unwrap();
            writeln!(out, "  {STRING_FREE_FN}(result);").unwrap();
            writeln!(out, "  return value.ToJs(env);").unwrap();
        }
        TypeRef::Optional { inner } => render_return(out, api, prefix, inner),
        TypeRef::Struct { name, .. } => {
            writeln!(out, "  Value value = ToValue(result);").unwrap();
            if struct_owns_memory(api, name) {
                writeln!(out, "  {}(&result);", c_free_symbol(prefix, name)).unwrap();
            }
            writeln!(out, "  return value.ToJs(env);").unwrap();
        }
        TypeRef::Vector { element } => match element.as_ref() {
            TypeRef::Object { name, .. } => {
                let field = c_list_field(name);
                writeln!(out, "  Value value = Value::Array();").unwrap();
                writeln!(out, "  for (long i = 0; i < result.count; ++i) {{").unwrap();
                writeln!(out, "    value.Push(Value::BigInt(result.{field}[i]));").unwrap();
                writeln!(out, "  }}").unwrap();
                writeln!(
                    out,
                    "  // The handles now belong to JS; free just the array."
                )
                .unwrap();
                writeln!(out, "  {}(&result);", c_list_release_symbol(prefix, name)).unwrap();
                writeln!(out, "  return value.ToJs(env);").unwrap();
            }
            _ => {
                writeln!(out, "  Value value = CopyStringList(result);").unwrap();
                writeln!(out, "  {STRING_LIST_FREE_FN}(&result);").unwrap();
                writeln!(out, "  return value.ToJs(env);").unwrap();
            }
        },
        TypeRef::Map { .. } => {
            writeln!(out, "  Value value = CopyStringMap(result);").unwrap();
            writeln!(out, "  {STRING_MAP_FREE_FN}(&result);").unwrap();
            writeln!(out, "  return value.ToJs(env);").unwrap();
        }
        other => {
            writeln!(out, "  return {}.ToJs(env);", value_expr(other, "result")).unwrap();
        }
    }
}

fn struct_owns_memory(api: &Api, name: &str) -> bool {
    api.headers
        .iter()
        .flat_map(|header| header.structs.iter())
        .any(|item| item.name == name && struct_has_owned_fields(item))
}

fn emitted_group<'a>(api: &'a Api, class: &Class) -> Option<&'a EventGroup> {
    let event = class.event.as_ref()?;
    api.headers
        .iter()
        .flat_map(|header| header.events.iter())
        .find(|group| &group.name == event)
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
    use heck::ToShoutySnakeCase;
    format!(
        "{}_{}_{}",
        prefix.trim_end_matches('_').to_shouty_snake_case(),
        struct_name.to_shouty_snake_case(),
        constant.to_shouty_snake_case()
    )
}

// ---------------------------------------------------------------------------
// <stem>.ts: the public TypeScript API
// ---------------------------------------------------------------------------

/// Hand-written helpers from `lib/runtime.ts`, imported by whichever module
/// mentions them.
const RUNTIME_EXPORTS: &[(&str, &str)] = &[
    ("native", "native."),
    ("NativeObject", "extends NativeObject"),
    ("wrapHandle", "wrapHandle("),
    ("runEventLoop", "runEventLoop("),
    ("stopEventLoop", "stopEventLoop("),
];

fn ts_file(api: &Api, header: &Header, origins: &TypeOrigins, prefix: &str) -> String {
    let mut body = String::new();

    for alias in &header.aliases {
        if origins.get(&alias.name) == Some(&header.stem) {
            writeln!(body, "export type {} = number;", alias.name).unwrap();
            writeln!(body).unwrap();
        }
    }
    for item in &header.enums {
        ts_enum(&mut body, item);
    }
    for item in &header.structs {
        ts_struct(&mut body, item, prefix);
    }
    for group in &header.events {
        ts_event(&mut body, group);
    }
    for class in &header.classes {
        ts_class(&mut body, api, class, prefix);
    }

    let mut out = String::from(BANNER);
    out.push('\n');
    let runtime: Vec<&str> = RUNTIME_EXPORTS
        .iter()
        .filter(|(_, marker)| body.contains(marker))
        .map(|(name, _)| *name)
        .collect();
    if !runtime.is_empty() {
        writeln!(
            out,
            "import {{ {} }} from \"./runtime.ts\";",
            runtime.join(", ")
        )
        .unwrap();
    }
    for (stem, names) in foreign_imports(api, header, origins) {
        writeln!(
            out,
            "import {{ {} }} from \"./{stem}.ts\";",
            names.join(", ")
        )
        .unwrap();
    }
    if out.lines().count() > 3 {
        writeln!(out).unwrap();
    }
    out.push_str(body.trim_end());
    out.push('\n');
    out
}

/// Imports from sibling modules, grouped by module. Names that only exist as
/// types are marked `type` so type stripping can drop them.
fn foreign_imports(
    api: &Api,
    header: &Header,
    origins: &TypeOrigins,
) -> Vec<(String, Vec<String>)> {
    let mut by_stem: std::collections::BTreeMap<String, Vec<String>> = Default::default();
    for name in codegen_shared::naming::foreign_types(header, origins) {
        let Some(stem) = origins.get(&name) else {
            continue;
        };
        // Variant names resolve too, but the TypeScript layer never names them.
        if is_event_variant(api, &name) {
            continue;
        }
        let spelled = if is_value_name(api, &name) {
            name
        } else {
            format!("type {name}")
        };
        by_stem.entry(stem.clone()).or_default().push(spelled);
    }
    by_stem.into_iter().collect()
}

fn is_event_variant(api: &Api, name: &str) -> bool {
    api.headers
        .iter()
        .flat_map(|header| header.events.iter())
        .flat_map(|group| group.variants.iter())
        .any(|variant| variant.name == name)
}

/// Whether `name` exists at runtime (a class, an enum object, or a struct with
/// a companion object) rather than only as a type.
fn is_value_name(api: &Api, name: &str) -> bool {
    api.headers.iter().any(|header| {
        header.classes.iter().any(|class| class.name == name)
            || header.enums.iter().any(|item| item.name == name)
            || header
                .structs
                .iter()
                .any(|item| item.name == name && struct_has_companion(item))
    })
}

fn struct_has_companion(item: &Struct) -> bool {
    !item.methods.is_empty() || !item.constants.is_empty()
}

fn ts_enum(out: &mut String, item: &codegen_shared::ir::Enum) {
    writeln!(out, "export const {} = {{", item.name).unwrap();
    for variant in &item.variants {
        writeln!(out, "  {}: {},", enum_member(&variant.name), variant.value).unwrap();
    }
    writeln!(out, "}} as const;").unwrap();
    writeln!(
        out,
        "export type {0} = (typeof {0})[keyof typeof {0}];",
        item.name
    )
    .unwrap();
    writeln!(out).unwrap();
}

fn ts_struct(out: &mut String, item: &Struct, prefix: &str) {
    writeln!(out, "export interface {} {{", item.name).unwrap();
    for field in &item.fields {
        let optional = matches!(field.ty, TypeRef::Optional { .. })
            || matches!(field.ty, TypeRef::Callback { .. });
        writeln!(
            out,
            "  {}{}: {};",
            js_field(&field.name),
            if optional { "?" } else { "" },
            ts_type(field.ty.unwrap_optional(), Position::Field)
        )
        .unwrap();
    }
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();

    if !struct_has_companion(item) {
        return;
    }
    let self_param = item.name.to_lower_camel_case();
    writeln!(out, "export const {} = {{", item.name).unwrap();
    for constant in &item.constants {
        writeln!(
            out,
            "  {}: Object.freeze(native.{} as {}),",
            constant,
            c_struct_constant(prefix, &item.name, constant),
            item.name
        )
        .unwrap();
    }
    for method in &item.methods {
        let mut params: Vec<String> = Vec::new();
        let mut args: Vec<String> = Vec::new();
        if !method.is_static {
            params.push(format!("{self_param}: {}", item.name));
            args.push(self_param.clone());
        }
        for param in &method.params {
            params.push(ts_param(param));
            args.push(ts_arg(param));
        }
        let symbol = c_struct_method_symbol(prefix, item, method);
        writeln!(
            out,
            "  {}({}): {} {{",
            ts_ident(&method.name.to_lower_camel_case()),
            params.join(", "),
            ts_type(&method.return_type, Position::Return)
        )
        .unwrap();
        writeln!(
            out,
            "    return {};",
            ts_wrap_result(
                &method.return_type,
                &format!("native.{symbol}({})", args.join(", "))
            )
        )
        .unwrap();
        writeln!(out, "  }},").unwrap();
    }
    writeln!(out, "}};").unwrap();
    writeln!(out).unwrap();
}

fn ts_event(out: &mut String, group: &EventGroup) {
    writeln!(out, "export type {} =", group.name).unwrap();
    for variant in &group.variants {
        let mut fields = vec![format!("type: \"{}\"", event_tag(&variant.discriminant))];
        for field in group.common.iter().chain(variant.fields.iter()) {
            fields.push(format!(
                "{}: {}",
                js_field(&field.name),
                ts_type(&field.ty, Position::Event)
            ));
        }
        writeln!(out, "  | {{ {} }}", fields.join("; ")).unwrap();
    }
    // Close the union on its own line so every variant diffs alike.
    let len = out.len();
    out.truncate(len - 1);
    writeln!(out, ";").unwrap();
    writeln!(out).unwrap();
}

fn ts_class(out: &mut String, api: &Api, class: &Class, prefix: &str) {
    if class.is_instance() {
        writeln!(
            out,
            "/** A native {}, held through an owned handle. */",
            class.name
        )
        .unwrap();
        writeln!(out, "export class {} extends NativeObject {{", class.name).unwrap();
        writeln!(
            out,
            "  /** Wraps a raw handle; an owned one is released on `dispose()` or collection. */"
        )
        .unwrap();
        writeln!(out, "  constructor(handle: bigint, owned = true) {{").unwrap();
        writeln!(
            out,
            "    super(handle, owned ? native.{} : undefined);",
            c_free_symbol(prefix, &class.name)
        )
        .unwrap();
        writeln!(out, "  }}").unwrap();
        writeln!(out).unwrap();
        for ctor in &class.constructors {
            let name = match constructor_suffix(class, ctor) {
                Some(suffix) => format!("create_{suffix}").to_lower_camel_case(),
                None => "create".to_string(),
            };
            let symbol = c_constructor_symbol(prefix, class, ctor);
            let params: Vec<String> = ctor.params.iter().map(ts_param).collect();
            let args: Vec<String> = ctor.params.iter().map(ts_arg).collect();
            writeln!(
                out,
                "  static {name}({}): {} | null {{",
                params.join(", "),
                class.name
            )
            .unwrap();
            writeln!(
                out,
                "    const handle: bigint = native.{symbol}({});",
                args.join(", ")
            )
            .unwrap();
            writeln!(
                out,
                "    return handle ? new {}(handle) : null;",
                class.name
            )
            .unwrap();
            writeln!(out, "  }}").unwrap();
            writeln!(out).unwrap();
        }
    } else {
        writeln!(out, "export class {} {{", class.name).unwrap();
        writeln!(out, "  private constructor() {{}}").unwrap();
        writeln!(out).unwrap();
    }

    for method in &class.methods {
        let symbol = c_method_symbol(prefix, class, method);
        if render_loop_method(out, &symbol) {
            continue;
        }
        ts_method(out, class, method, &symbol);
    }

    if class.is_instance() && class.native_object {
        writeln!(
            out,
            "  /** The platform object behind this handle, as an address. */"
        )
        .unwrap();
        writeln!(out, "  get nativeObject(): bigint {{").unwrap();
        writeln!(
            out,
            "    return native.{}(this.nativeHandle);",
            c_native_object_symbol(prefix, &class.name)
        )
        .unwrap();
        writeln!(out, "  }}").unwrap();
        writeln!(out).unwrap();
    }

    if let Some(group) = emitted_group(api, class) {
        ts_listener(out, class, group, prefix);
    }

    let len = out.trim_end().len();
    out.truncate(len);
    writeln!(out).unwrap();
    writeln!(out, "}}").unwrap();
    writeln!(out).unwrap();
}

/// The `Application` loop entry points, rerouted through `lib/runtime.ts`.
/// Returns false for every other symbol.
fn render_loop_method(out: &mut String, symbol: &str) -> bool {
    match symbol {
        LOOP_RUN => {
            writeln!(
                out,
                "  /**\n   * Runs the platform event loop until `quit()`; resolves with the exit code.\n   *\n   * The loop is pumped from the JS event loop, so timers, promises and I/O\n   * keep running. With `window`, it is shown and made the primary window.\n   */"
            )
            .unwrap();
            writeln!(out, "  static run(window?: Window): Promise<number> {{").unwrap();
            writeln!(out, "    return runEventLoop(window?.nativeHandle ?? 0n);").unwrap();
            writeln!(out, "  }}").unwrap();
            writeln!(out).unwrap();
            true
        }
        // Folded into `run(window?)` above.
        LOOP_RUN_WITH_WINDOW => true,
        LOOP_QUIT => {
            writeln!(
                out,
                "  /** Stops the loop started by `run()`, which then resolves with `exitCode`. */"
            )
            .unwrap();
            writeln!(out, "  static quit(exitCode = 0): void {{").unwrap();
            writeln!(out, "    stopEventLoop(exitCode);").unwrap();
            writeln!(out, "  }}").unwrap();
            writeln!(out).unwrap();
            true
        }
        _ => false,
    }
}

fn ts_method(out: &mut String, class: &Class, method: &Method, symbol: &str) {
    let instance = class.is_instance() && !method.is_static;
    let name = ts_ident(&swift_method_name(class, method));
    let mut args: Vec<String> = Vec::new();
    if instance {
        args.push("this.nativeHandle".to_string());
    }
    args.extend(method.params.iter().map(ts_arg));
    let call = format!("native.{symbol}({})", args.join(", "));
    let result = ts_wrap_result(&method.return_type, &call);
    let return_type = ts_type(&method.return_type, Position::Return);

    let getter = is_binding_accessor(class, method) && method.params.is_empty();
    if getter {
        writeln!(out, "  get {name}(): {return_type} {{").unwrap();
    } else {
        let params: Vec<String> = method.params.iter().map(ts_param).collect();
        let modifier = if instance { "" } else { "static " };
        writeln!(
            out,
            "  {modifier}{name}({}): {return_type} {{",
            params.join(", ")
        )
        .unwrap();
    }
    if matches!(method.return_type, TypeRef::Void) {
        writeln!(out, "    {result};").unwrap();
    } else {
        writeln!(out, "    return {result};").unwrap();
    }
    writeln!(out, "  }}").unwrap();
    writeln!(out).unwrap();
}

fn ts_listener(out: &mut String, class: &Class, group: &EventGroup, prefix: &str) {
    let add = c_add_listener_symbol(prefix, &class.name);
    let remove = c_remove_listener_symbol(prefix, &class.name);
    let (modifier, self_arg) = if class.is_instance() {
        ("", "this.nativeHandle, ")
    } else {
        ("static ", "")
    };

    // Handles inside an event are borrowed for the duration of the callback;
    // wrap them without taking ownership.
    let objects: Vec<(String, String)> = group
        .common
        .iter()
        .chain(
            group
                .variants
                .iter()
                .flat_map(|variant| variant.fields.iter()),
        )
        .filter_map(|field| match field.ty.unwrap_optional() {
            TypeRef::Object { name, .. } => Some((js_field(&field.name), name.clone())),
            _ => None,
        })
        .collect();

    writeln!(
        out,
        "  /** Calls `listener` for every {} this {} emits; returns the listener id. */",
        group.name, class.name
    )
    .unwrap();
    writeln!(
        out,
        "  {modifier}addListener(listener: (event: {}) => void): number {{",
        group.name
    )
    .unwrap();
    if objects.is_empty() {
        writeln!(out, "    return native.{add}({self_arg}listener);").unwrap();
    } else {
        writeln!(
            out,
            "    return native.{add}({self_arg}(event: Record<string, unknown>) => {{"
        )
        .unwrap();
        for (field, name) in &objects {
            writeln!(out, "      if (typeof event.{field} === \"bigint\") {{").unwrap();
            writeln!(
                out,
                "        event.{field} = event.{field} ? new {name}(event.{field}, false) : null;"
            )
            .unwrap();
            writeln!(out, "      }}").unwrap();
        }
        writeln!(out, "      listener(event as unknown as {});", group.name).unwrap();
        writeln!(out, "    }});").unwrap();
    }
    writeln!(out, "  }}").unwrap();
    writeln!(out).unwrap();
    writeln!(
        out,
        "  /** Unregisters a listener; returns false if the id is unknown. */"
    )
    .unwrap();
    writeln!(
        out,
        "  {modifier}removeListener(listenerId: number): boolean {{"
    )
    .unwrap();
    writeln!(out, "    return native.{remove}({self_arg}listenerId);").unwrap();
    writeln!(out, "  }}").unwrap();
    writeln!(out).unwrap();
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum Position {
    Param,
    Return,
    Field,
    Event,
}

fn ts_type(ty: &TypeRef, position: Position) -> String {
    match ty {
        TypeRef::Void => "void".to_string(),
        TypeRef::Bool => "boolean".to_string(),
        TypeRef::Int { .. } | TypeRef::Float { .. } => "number".to_string(),
        TypeRef::String | TypeRef::CString => match position {
            // A borrowed C string in an event can be null.
            Position::Event => "string | null".to_string(),
            _ => "string".to_string(),
        },
        TypeRef::Alias { name, .. } | TypeRef::Enum { name, .. } | TypeRef::Struct { name, .. } => {
            name.clone()
        }
        TypeRef::Object { name, shared, .. } => match position {
            Position::Param if !shared => name.clone(),
            _ => format!("{name} | null"),
        },
        TypeRef::Vector { element } => match element.as_ref() {
            TypeRef::Object { name, .. } => format!("{name}[]"),
            other => format!("{}[]", ts_type(other, Position::Field)),
        },
        TypeRef::Map { .. } => "Record<string, string>".to_string(),
        TypeRef::Optional { inner } => {
            let base = ts_type(inner, position);
            if base.ends_with("| null") {
                base
            } else if base.contains("=>") {
                format!("({base}) | null")
            } else {
                format!("{base} | null")
            }
        }
        TypeRef::Callback { params } => {
            let args: Vec<String> = params
                .iter()
                .enumerate()
                .map(|(index, ty)| format!("arg{index}: {}", ts_type(ty, Position::Event)))
                .collect();
            format!("({}) => void", args.join(", "))
        }
        TypeRef::RawPointer => "bigint".to_string(),
        TypeRef::Unsupported { .. } => "unknown".to_string(),
    }
}

fn ts_param(param: &Param) -> String {
    let name = ts_ident(&param.name.to_lower_camel_case());
    format!("{name}: {}", ts_type(&param.ty, Position::Param))
}

/// How a public argument is handed to the raw function.
fn ts_arg(param: &Param) -> String {
    let name = ts_ident(&param.name.to_lower_camel_case());
    match &param.ty {
        TypeRef::Object { shared: false, .. } => format!("{name}.nativeHandle"),
        TypeRef::Object { shared: true, .. } => format!("{name}?.nativeHandle ?? 0n"),
        TypeRef::Optional { inner } if matches!(inner.as_ref(), TypeRef::Object { .. }) => {
            format!("{name}?.nativeHandle ?? 0n")
        }
        _ => name,
    }
}

/// Converts what the raw function returned into the public type.
fn ts_wrap_result(ty: &TypeRef, call: &str) -> String {
    match ty.unwrap_optional() {
        TypeRef::Object { name, .. } => format!("wrapHandle({name}, {call})"),
        TypeRef::Vector { element } => match element.as_ref() {
            TypeRef::Object { name, .. } => {
                format!("({call} as bigint[]).map((handle) => new {name}(handle))")
            }
            _ => call.to_string(),
        },
        _ => call.to_string(),
    }
}

fn js_field(name: &str) -> String {
    name.to_lower_camel_case()
}

/// `Focused` -> `"focused"`, the `type` tag of an event object.
fn event_tag(discriminant: &str) -> String {
    discriminant.to_lower_camel_case()
}

fn enum_member(name: &str) -> String {
    name.strip_prefix('k').unwrap_or(name).to_upper_camel_case()
}

const TS_RESERVED: &[&str] = &[
    "break",
    "case",
    "catch",
    "class",
    "const",
    "continue",
    "debugger",
    "default",
    "delete",
    "do",
    "else",
    "enum",
    "export",
    "extends",
    "false",
    "finally",
    "for",
    "function",
    "if",
    "import",
    "in",
    "instanceof",
    "new",
    "null",
    "return",
    "super",
    "switch",
    "this",
    "throw",
    "true",
    "try",
    "typeof",
    "var",
    "void",
    "while",
    "with",
    "let",
    "static",
    "yield",
    "await",
    "implements",
    "interface",
    "package",
    "private",
    "protected",
    "public",
    "arguments",
    "eval",
];

fn ts_ident(name: &str) -> String {
    if TS_RESERVED.contains(&name) {
        format!("{name}_")
    } else {
        name.to_string()
    }
}
