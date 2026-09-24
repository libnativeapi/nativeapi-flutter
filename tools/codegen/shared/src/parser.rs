use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};

use anyhow::{anyhow, Context, Result};
use clang::diagnostic::Severity;
use clang::{Accessibility, Clang, Entity, EntityKind, Index, Type, TypeKind};

use crate::ir::{
    Alias, Api, Class, ClassKind, Constructor, Enum, EnumVariant, EventGroup, EventVariant, Field,
    Header, Method, Param, Struct, TypeRef,
};

/// Base class that opts a class into the generated `GetNativeObject()` accessor.
const NATIVE_OBJECT_PROVIDER: &str = "NativeObjectProvider";

/// Root of every event hierarchy. Subclasses of it are data, not handles.
const EVENT_BASE: &str = "Event";

/// Base template that marks a class as emitting events.
const EVENT_EMITTER: &str = "EventEmitter";

/// What kind of declaration a name in the API surface refers to.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum TypeCategory {
    Enum,
    Struct,
    Class,
    /// A class in an `Event` hierarchy: passed by value in callbacks, never as
    /// a handle.
    Event,
    /// An integer type alias declared by one of the headers.
    Alias,
}

/// One entry in the type index.
#[derive(Debug, Clone)]
struct TypeEntry {
    category: TypeCategory,
    /// Name used in generated code. Nested types are flattened
    /// (`PositioningStrategy::Type` -> `PositioningStrategyType`) because the C
    /// ABI has no nesting.
    name: String,
    /// C++ spelling, used verbatim in the generated glue.
    qualified_name: String,
}

/// Every user-defined type declared by the headers we generate for. Built per
/// translation unit, but spanning all headers in the generation set so that a
/// header can reference types declared by the headers it includes.
///
/// Keyed by every spelling a signature might use: the bare name (`Point`) and,
/// for nested types, the enclosing path as well (`PositioningStrategy::Type`).
type TypeIndex = HashMap<String, TypeEntry>;

pub fn parse(headers: &[PathBuf], includes: &[PathBuf]) -> Result<Api> {
    let clang = Clang::new().map_err(|err| anyhow!("failed to initialize libclang: {err}"))?;
    let index = Index::new(&clang, false, false);
    let mut parsed_headers = Vec::new();
    let mut diagnostics = Vec::new();

    // Types are only resolvable if they are declared by a header we generate
    // bindings for; anything else has no C ABI representation.
    let scope: HashSet<PathBuf> = headers
        .iter()
        .map(|path| path.canonicalize().unwrap_or_else(|_| path.clone()))
        .collect();

    for header in headers {
        let parsed = parse_header(&index, header, includes, &scope)
            .with_context(|| format!("failed to parse {}", header.display()))?;
        diagnostics.extend(parsed.1);
        parsed_headers.push(parsed.0);
    }

    Ok(Api {
        headers: parsed_headers,
        diagnostics,
    })
}

fn parse_header(
    index: &Index,
    header: &Path,
    includes: &[PathBuf],
    scope: &HashSet<PathBuf>,
) -> Result<(Header, Vec<String>)> {
    let mut args = vec![
        "-x".to_string(),
        "c++".to_string(),
        "-std=c++17".to_string(),
    ];
    // libclang does not apply the driver's platform defaults, so without this
    // the standard library is missing and `std::string` silently degrades to
    // `int` in the AST.
    args.extend(platform_args());
    for include in includes {
        // Clang's include search does not accept Windows verbatim path prefixes.
        let path = include.to_string_lossy();
        args.push(format!("-I{}", path.strip_prefix(r"\\?\").unwrap_or(&path).replace('\\', "/")));
    }

    let tu = index
        .parser(header)
        .arguments(&args)
        .parse()
        .with_context(|| format!("libclang could not parse {}", header.display()))?;

    // A missing include yields a valid-looking AST full of `int`s, so refuse to
    // generate anything from a translation unit that did not compile cleanly.
    let fatal: Vec<String> = tu
        .get_diagnostics()
        .into_iter()
        .filter(|diagnostic| {
            matches!(
                diagnostic.get_severity(),
                Severity::Error | Severity::Fatal
            )
        })
        .map(|diagnostic| diagnostic.get_text())
        .collect();
    if !fatal.is_empty() {
        return Err(anyhow!(
            "libclang reported errors in {}:\n  {}",
            header.display(),
            fatal.join("\n  ")
        ));
    }

    let mut diagnostics = Vec::new();
    let root = tu.get_entity();

    // Collect ALL namespace blocks named "nativeapi" (there may be multiple
    // from different included headers). Children must be gathered from all of
    // them since C++ allows re-opening the same namespace across multiple files.
    let namespaces: Vec<_> = root
        .get_children()
        .into_iter()
        .filter(|entity| {
            entity.get_kind() == EntityKind::Namespace
                && entity.get_name().as_deref() == Some("nativeapi")
        })
        .collect();
    if namespaces.is_empty() {
        return Err(anyhow!(
            "missing namespace nativeapi in {}",
            header.display()
        ));
    }

    let header_canon = header
        .canonicalize()
        .unwrap_or_else(|_| header.to_path_buf());

    // Index every type declared by any in-scope header reachable from this
    // translation unit, so cross-header references (e.g. `Point` from
    // geometry.h used by display.h) resolve instead of degrading to
    // `Unsupported`.
    let mut types: TypeIndex = HashMap::new();
    for ns in &namespaces {
        for child in ns.get_children() {
            if !is_in_scope(&child, scope) {
                continue;
            }
            index_entity(&child, None, &mut types);
        }
    }

    let mut enums = Vec::new();
    let mut structs = Vec::new();
    let mut classes = Vec::new();
    let mut aliases = Vec::new();
    let mut event_classes = Vec::new();

    for namespace in &namespaces {
        for child in namespace.get_children() {
            if !is_from_file(&child, &header_canon) {
                continue;
            }

            match child.get_kind() {
                EntityKind::EnumDecl => {
                    if let Some(item) = parse_enum(&child, None) {
                        enums.push(item);
                    }
                }
                EntityKind::StructDecl => {
                    if let Some(item) = parse_struct(&child, &types, &mut diagnostics) {
                        structs.push(item);
                    }
                }
                EntityKind::ClassDecl => {
                    // Forward declarations (`class Window;`) carry no members.
                    if !child.is_definition() {
                        continue;
                    }
                    if is_event_class(&child) {
                        event_classes.push(child);
                        continue;
                    }
                    // Nested enums have no C++ enclosing scope in C, so they are
                    // hoisted to the header's top level under a flattened name.
                    enums.extend(nested_enums(&child));
                    if let Some(item) = parse_class(&child, &types, &mut diagnostics) {
                        classes.push(item);
                    }
                }
                EntityKind::TypedefDecl | EntityKind::TypeAliasDecl => {
                    if let Some(item) = parse_alias(&child, &types) {
                        aliases.push(item);
                    }
                }
                EntityKind::FunctionDecl => {
                    diagnostics.push(format!(
                        "skipped free function {}: free functions are outside the MVP",
                        child.get_display_name().unwrap_or_default()
                    ));
                }
                _ => {}
            }
        }
    }

    let events = parse_event_groups(&event_classes, &types);

    Ok((
        Header {
            path: header_canon,
            stem: header
                .file_stem()
                .and_then(|name| name.to_str())
                .unwrap_or("generated")
                .to_string(),
            namespace: "nativeapi".to_string(),
            enums,
            structs,
            classes,
            aliases,
            events,
        },
        diagnostics,
    ))
}

/// Records `entity` and every nested type it declares under all the spellings a
/// signature might use for them.
fn index_entity(entity: &Entity, enclosing: Option<&str>, types: &mut TypeIndex) {
    let category = match entity.get_kind() {
        EntityKind::EnumDecl => TypeCategory::Enum,
        EntityKind::StructDecl => TypeCategory::Struct,
        EntityKind::ClassDecl => {
            if is_event_class(entity) {
                TypeCategory::Event
            } else {
                TypeCategory::Class
            }
        }
        EntityKind::TypedefDecl | EntityKind::TypeAliasDecl => TypeCategory::Alias,
        _ => return,
    };
    let Some(name) = entity.get_name() else {
        return;
    };

    let (ir_name, qualified_name, path) = match enclosing {
        // `PositioningStrategy::Type` cannot nest in C, so it is flattened into
        // `PositioningStrategyType` while the C++ glue keeps the real spelling.
        Some(outer) => (
            format!("{outer}{name}"),
            format!("nativeapi::{outer}::{name}"),
            format!("{outer}::{name}"),
        ),
        None => (
            name.clone(),
            format!("nativeapi::{name}"),
            name.clone(),
        ),
    };

    let entry = TypeEntry {
        category,
        name: ir_name,
        qualified_name,
    };
    types.insert(path, entry.clone());
    // Bare-name lookup only when nothing else claims it; an outer type always
    // wins over a nested one, which is why `Type` alone stays ambiguous-safe.
    types.entry(name.clone()).or_insert(entry);

    if matches!(entity.get_kind(), EntityKind::ClassDecl | EntityKind::StructDecl)
        && entity.is_definition()
    {
        for child in entity.get_children() {
            if child.get_accessibility() == Some(Accessibility::Public) {
                index_entity(&child, Some(&name), types);
            }
        }
    }
}

/// Public enums declared inside a class, hoisted to header scope.
fn nested_enums(entity: &Entity) -> Vec<Enum> {
    entity
        .get_children()
        .into_iter()
        .filter(|child| {
            child.get_kind() == EntityKind::EnumDecl
                && child.get_accessibility() == Some(Accessibility::Public)
        })
        .filter_map(|child| parse_enum(&child, entity.get_name().as_deref()))
        .collect()
}

/// Extra clang arguments the compiler driver would normally inject. On macOS
/// the SDK path is required for the C++ standard library to resolve.
fn platform_args() -> Vec<String> {
    if !cfg!(target_os = "macos") {
        return Vec::new();
    }
    let output = std::process::Command::new("xcrun")
        .args(["--show-sdk-path"])
        .output()
        .ok()
        .filter(|output| output.status.success());
    match output {
        Some(output) => {
            let sdk = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if sdk.is_empty() {
                Vec::new()
            } else {
                vec!["-isysroot".to_string(), sdk]
            }
        }
        None => Vec::new(),
    }
}

/// `typedef IdAllocator::IdType WindowId;` and friends. Only integer aliases
/// are kept: anything else is either already a named type in its own right or
/// has no separate C spelling.
fn parse_alias(entity: &Entity, types: &TypeIndex) -> Option<Alias> {
    let name = entity.get_name()?;
    let underlying = map_type(entity.get_typedef_underlying_type()?, types);
    if !matches!(underlying, TypeRef::Int { .. }) {
        return None;
    }
    Some(Alias {
        qualified_name: format!("nativeapi::{name}"),
        name,
        underlying,
    })
}

fn parse_enum(entity: &Entity, enclosing: Option<&str>) -> Option<Enum> {
    let name = entity.get_name()?;
    let variants = entity
        .get_children()
        .into_iter()
        .filter(|child| child.get_kind() == EntityKind::EnumConstantDecl)
        .filter_map(|child| {
            let (value, _) = child.get_enum_constant_value()?;
            Some(EnumVariant {
                name: child.get_name()?,
                value,
            })
        })
        .collect();

    match enclosing {
        Some(outer) => Some(Enum {
            qualified_name: format!("nativeapi::{outer}::{name}"),
            name: format!("{outer}{name}"),
            variants,
        }),
        None => Some(Enum {
            qualified_name: format!("nativeapi::{name}"),
            name,
            variants,
        }),
    }
}

fn parse_struct(
    entity: &Entity,
    types: &TypeIndex,
    diagnostics: &mut Vec<String>,
) -> Option<Struct> {
    let name = entity.get_name()?;
    let fields = entity
        .get_children()
        .into_iter()
        .filter(|child| child.get_kind() == EntityKind::FieldDecl)
        .filter_map(|field| {
            Some(Field {
                name: field.get_name()?,
                ty: map_entity_type(&field, types)?,
            })
        })
        .collect();

    // Structs are values, so only helpers that neither mutate nor allocate make
    // sense across the ABI: static factories and const accessors.
    let mut methods = Vec::new();
    for child in entity.get_children() {
        if child.get_kind() != EntityKind::Method
            || child.get_accessibility() != Some(Accessibility::Public)
        {
            continue;
        }
        let method_name = child.get_name().unwrap_or_default();
        if method_name.starts_with("operator") {
            continue;
        }
        if !child.is_static_method() && !child.is_const_method() {
            continue;
        }
        match parse_method(&child, types) {
            Some(method) if method_is_supported(&method) => methods.push(method),
            Some(method) => diagnostics.push(format!(
                "skipped {name}::{}: unsupported type in signature: {}",
                method.name,
                unsupported_signature_types(&method).join(", ")
            )),
            None => {}
        }
    }

    // `static const Color Black;` and friends: named values of the struct's own
    // type, exported as `extern const` so C callers can use them directly.
    let constants = entity
        .get_children()
        .into_iter()
        .filter(|child| {
            child.get_kind() == EntityKind::VarDecl
                && child.get_accessibility() == Some(Accessibility::Public)
        })
        .filter_map(|child| {
            let ty = child.get_type()?;
            let short = normalize_type_name(&ty.get_display_name());
            let short = short.rsplit("::").next().unwrap_or(&short);
            (short == name).then(|| child.get_name())?
        })
        .collect();

    Some(Struct {
        qualified_name: format!("nativeapi::{name}"),
        name,
        fields,
        methods,
        constants,
    })
}

/// Whether this class is part of an `Event` hierarchy, directly or through a
/// chain of intermediate event classes.
fn is_event_class(entity: &Entity) -> bool {
    if entity.get_kind() != EntityKind::ClassDecl || !entity.is_definition() {
        return false;
    }
    entity
        .get_children()
        .into_iter()
        .filter(|child| child.get_kind() == EntityKind::BaseSpecifier)
        .any(|child| {
            let Some(name) = base_name(&child) else {
                return false;
            };
            if name == EVENT_BASE {
                return true;
            }
            child
                .get_type()
                .and_then(|ty| ty.get_declaration())
                .is_some_and(|decl| is_event_class(&decl))
        })
}

/// Short name of a base specifier, with any template arguments stripped:
/// `EventEmitter<WindowEvent>` -> `EventEmitter`.
fn base_name(base: &Entity) -> Option<String> {
    let display = base.get_type()?.get_display_name();
    let stripped = display.split('<').next().unwrap_or(&display).to_string();
    Some(
        stripped
            .rsplit("::")
            .next()
            .unwrap_or(&stripped)
            .trim()
            .to_string(),
    )
}

/// Event payload carried by `EventEmitter<T>`, if the class derives from one.
fn emitted_event(entity: &Entity) -> Option<String> {
    entity
        .get_children()
        .into_iter()
        .filter(|child| child.get_kind() == EntityKind::BaseSpecifier)
        .find(|child| base_name(child).as_deref() == Some(EVENT_EMITTER))
        .and_then(|child| {
            let ty = child.get_type()?;
            let arg = ty.get_template_argument_types()?.first().copied().flatten()?;
            let name = arg.get_display_name();
            Some(name.rsplit("::").next().unwrap_or(&name).to_string())
        })
}

/// Groups the event classes of a header into hierarchies: one base per group,
/// with the concrete events under it. Nothing else in the pipeline treats these
/// as classes, so their accessors become struct fields rather than methods.
fn parse_event_groups(entities: &[Entity], types: &TypeIndex) -> Vec<EventGroup> {
    // Bases first: a group's root is the class whose own base is `Event`.
    let mut groups: Vec<EventGroup> = Vec::new();
    for entity in entities {
        let Some(name) = entity.get_name() else {
            continue;
        };
        let derives_directly = entity
            .get_children()
            .into_iter()
            .filter(|child| child.get_kind() == EntityKind::BaseSpecifier)
            .any(|child| base_name(&child).as_deref() == Some(EVENT_BASE));
        if !derives_directly {
            continue;
        }
        groups.push(EventGroup {
            qualified_name: format!("nativeapi::{name}"),
            common: event_fields(entity, types),
            name,
            variants: Vec::new(),
        });
    }

    for entity in entities {
        let Some(name) = entity.get_name() else {
            continue;
        };
        let Some(group) = groups
            .iter_mut()
            .find(|group| inherits_from(entity, &group.name) && group.name != name)
        else {
            continue;
        };
        // `WindowFocusedEvent` in group `WindowEvent` -> `Focused`.
        let discriminant = discriminant_of(&name, &group.name);
        group.variants.push(EventVariant {
            qualified_name: format!("nativeapi::{name}"),
            fields: event_fields(entity, types),
            discriminant,
            name,
        });
    }

    groups.retain(|group| !group.variants.is_empty());
    groups
}

/// `WindowFocusedEvent` + base `WindowEvent` -> `Focused`; falls back to the
/// full name when the two share no affix (`MenuItemClickedEvent` in `MenuEvent`
/// -> `MenuItemClicked`).
fn discriminant_of(name: &str, base: &str) -> String {
    let stem = name.strip_suffix("Event").unwrap_or(name);
    let base_stem = base.strip_suffix("Event").unwrap_or(base);
    stem.strip_prefix(base_stem)
        .filter(|rest| !rest.is_empty())
        .unwrap_or(stem)
        .to_string()
}

fn inherits_from(entity: &Entity, base: &str) -> bool {
    entity
        .get_children()
        .into_iter()
        .filter(|child| child.get_kind() == EntityKind::BaseSpecifier)
        .any(|child| {
            if base_name(&child).as_deref() == Some(base) {
                return true;
            }
            child
                .get_type()
                .and_then(|ty| ty.get_declaration())
                .is_some_and(|decl| inherits_from(&decl, base))
        })
}

/// Const, argument-less accessors on an event class, as payload fields.
/// `GetNewPosition()` becomes `new_position`.
fn event_fields(entity: &Entity, types: &TypeIndex) -> Vec<Field> {
    entity
        .get_children()
        .into_iter()
        .filter(|child| {
            child.get_kind() == EntityKind::Method
                && child.get_accessibility() == Some(Accessibility::Public)
                && child.is_const_method()
                && child.get_arguments().map(|args| args.is_empty()).unwrap_or(false)
        })
        .filter_map(|child| {
            let name = child.get_name()?;
            // Every event has these; they carry no payload.
            if name == "GetTypeName" || name == "GetTimestamp" {
                return None;
            }
            let stem = name.strip_prefix("Get")?;
            let ty = map_type(child.get_result_type()?, types);
            if !ty.is_supported() {
                return None;
            }
            Some(Field {
                name: stem.to_string(),
                ty,
            })
        })
        .collect()
}

fn parse_class(
    entity: &Entity,
    types: &TypeIndex,
    diagnostics: &mut Vec<String>,
) -> Option<Class> {
    let name = entity.get_name()?;
    let mut singleton = false;
    let mut methods = Vec::new();
    let mut constructors = Vec::new();

    for child in entity.get_children() {
        match child.get_kind() {
            EntityKind::Method => {
                let method_name = child.get_name().unwrap_or_default();
                if method_name == "GetInstance" {
                    singleton = true;
                    continue;
                }
                // Only the public surface crosses the ABI boundary.
                if child.get_accessibility() != Some(Accessibility::Public) {
                    continue;
                }
                if method_name.starts_with("operator") {
                    continue;
                }
                match parse_method(&child, types) {
                    Some(method) if method_is_supported(&method) => methods.push(method),
                    Some(method) => diagnostics.push(format!(
                        "skipped {name}::{}: unsupported type in signature: {}",
                        method.name,
                        unsupported_signature_types(&method).join(", ")
                    )),
                    None => diagnostics.push(format!(
                        "skipped {name}::{}: unsupported method shape",
                        child.get_display_name().unwrap_or_default()
                    )),
                }
            }
            EntityKind::Constructor => {
                if child.get_accessibility() != Some(Accessibility::Public) {
                    continue;
                }
                match parse_params(&child, types) {
                    Some(params) => {
                        // Copy/move constructors have no meaning across the ABI.
                        if is_copy_or_move(&params, &name) {
                            continue;
                        }
                        if let Some(unsupported) = unsupported_param(&params) {
                            diagnostics.push(format!(
                                "skipped {name} constructor: unsupported parameter {unsupported}"
                            ));
                            continue;
                        }
                        constructors.push(Constructor { params });
                    }
                    None => diagnostics.push(format!(
                        "skipped {name} constructor: unsupported parameter shape"
                    )),
                }
            }
            EntityKind::Destructor => {}
            _ => {}
        }
    }

    let kind = if singleton {
        ClassKind::Singleton
    } else {
        ClassKind::Instance
    };

    // An abstract base with no constructor can never be the dynamic type behind
    // a handle — the handle table tags slots with the concrete type — so
    // exposing one would produce functions no caller could ever satisfy.
    if kind == ClassKind::Instance && constructors.is_empty() && has_pure_virtual(entity) {
        diagnostics.push(format!(
            "skipped class {name}: abstract base with no public constructor"
        ));
        return None;
    }

    // An emitter with no bindable methods is still worth exposing: its listener
    // registration is the whole API.
    if kind == ClassKind::Instance && methods.is_empty() && emitted_event(entity).is_none() {
        diagnostics.push(format!(
            "skipped class {name}: no bindable public methods"
        ));
        return None;
    }

    if kind == ClassKind::Singleton {
        constructors.clear();
    }

    Some(Class {
        qualified_name: format!("nativeapi::{name}"),
        event: emitted_event(entity),
        name,
        kind,
        native_object: derives_from(entity, NATIVE_OBJECT_PROVIDER),
        constructors,
        methods,
    })
}

fn has_pure_virtual(entity: &Entity) -> bool {
    entity
        .get_children()
        .into_iter()
        .any(|child| child.get_kind() == EntityKind::Method && child.is_pure_virtual_method())
}

/// Whether `entity` lists `base` (directly) among its base specifiers.
fn derives_from(entity: &Entity, base: &str) -> bool {
    entity
        .get_children()
        .into_iter()
        .filter(|child| child.get_kind() == EntityKind::BaseSpecifier)
        .any(|child| {
            child
                .get_type()
                .map(|ty| ty.get_display_name())
                .map(|name| name.rsplit("::").next().unwrap_or(&name).to_string())
                .is_some_and(|name| name == base)
        })
}

fn parse_params(entity: &Entity, types: &TypeIndex) -> Option<Vec<Param>> {
    entity
        .get_arguments()
        .unwrap_or_default()
        .into_iter()
        .map(|arg| {
            Some(Param {
                name: arg.get_name().unwrap_or_else(|| "arg".to_string()),
                ty: map_entity_type(&arg, types)?,
            })
        })
        .collect::<Option<Vec<_>>>()
}

/// `Preferences(const Preferences&)` / `Preferences(Preferences&&)`.
fn is_copy_or_move(params: &[Param], class_name: &str) -> bool {
    matches!(params, [only] if matches!(&only.ty, TypeRef::Object { name, .. } if name == class_name))
}

/// A constructor is bindable when every parameter has a C representation. Raw
/// platform pointers do (`void*`), so `Window(void* native_window)` survives
/// here; it is the language generators that drop it, since a binding user has
/// no safe way to produce an `NSWindow*`.
fn unsupported_param(params: &[Param]) -> Option<String> {
    params
        .iter()
        .find(|param| !param.ty.is_supported())
        .map(|param| format!("{} {}", param.ty.display_name(), param.name))
}

fn parse_method(entity: &Entity, types: &TypeIndex) -> Option<Method> {
    let name = entity.get_name()?;
    let return_type = entity
        .get_result_type()
        .map(|ty| map_type(ty, types))
        .unwrap_or(TypeRef::Void);
    let params = parse_params(entity, types)?;

    Some(Method {
        name,
        return_type,
        params,
        is_const: entity.is_const_method(),
        is_static: entity.is_static_method(),
    })
}

fn method_is_supported(method: &Method) -> bool {
    // A callback can be handed *to* the library, but handing one back would
    // require the binding to marshal a C++ closure into a function pointer,
    // which has nowhere to store its captures.
    if matches!(method.return_type.unwrap_optional(), TypeRef::Callback { .. }) {
        return false;
    }
    // Same reasoning for a borrowed `const char*` return: nothing on the C side
    // can know how long it stays valid.
    if matches!(method.return_type, TypeRef::CString) {
        return false;
    }
    // An optional struct is a nullable pointer, which works as a parameter but
    // not as a return value — the pointee would have nowhere to live.
    if let TypeRef::Optional { inner } = &method.return_type {
        if matches!(inner.as_ref(), TypeRef::Struct { .. }) {
            return false;
        }
    }
    method.return_type.is_supported() && method.params.iter().all(|param| param.ty.is_supported())
}

fn unsupported_signature_types(method: &Method) -> Vec<String> {
    let mut names = Vec::new();
    if !method.return_type.is_supported() {
        names.push(format!("return {}", method.return_type.display_name()));
    }
    for param in &method.params {
        if !param.ty.is_supported() {
            names.push(format!("param {} {}", param.name, param.ty.display_name()));
        }
    }
    names
}

fn map_entity_type(entity: &Entity, types: &TypeIndex) -> Option<TypeRef> {
    let mapped = map_type(entity.get_type()?, types);
    // Guard against libclang degrading `std::string` to `int` when a standard
    // library header failed to resolve. Only consult the spelling when the
    // mapped type looks like that degradation, otherwise a
    // `std::vector<std::string>` would be mistaken for a bare string.
    if matches!(mapped, TypeRef::Int { .. } | TypeRef::Unsupported { .. })
        && entity_tokens_contain_std_string(entity)
    {
        return Some(TypeRef::String);
    }
    Some(mapped)
}

fn map_type(ty: Type, types: &TypeIndex) -> TypeRef {
    if matches!(
        ty.get_kind(),
        TypeKind::LValueReference | TypeKind::RValueReference
    ) {
        if let Some(pointee) = ty.get_pointee_type() {
            return map_type(pointee, types);
        }
    }

    // The published C ABI uses unsigned long for size_t parameters/results.
    // Preserve that spelling on LLP64 hosts too; canonicalizing MSVC's size_t
    // to unsigned long long otherwise makes bindings disagree with that ABI.
    // Changing the ABI's integer widths is tracked separately in spec C-ABI A1.
    if matches!(ty.get_display_name().as_str(), "size_t" | "std::size_t") {
        return TypeRef::Int { name: "unsigned long".to_string() };
    }

    // A named integer alias keeps its own C spelling: `WindowId` must not
    // collapse into a bare `unsigned int` across the ABI. Matched on the
    // spelling rather than on TypeKind::Typedef, because clang hands back an
    // elaborated type here and the typedef kind never surfaces.
    if let Some(entry) = alias_entry(&ty, types) {
        let underlying = map_type(ty.get_canonical_type(), types);
        if matches!(underlying, TypeRef::Int { .. }) {
            return TypeRef::Alias {
                name: entry.name.clone(),
                underlying: Box::new(underlying),
            };
        }
    }

    // A `using` alias hides the template behind its own name, so resolve
    // through it: `std::optional<WindowWillShowHook>` must still be recognised
    // as an optional callback.
    let (decl_name, ty) = match template_spelling(&ty) {
        Some(resolved) => resolved,
        None => (type_decl_name(&ty), ty),
    };
    let decl_name = decl_name;

    if decl_name
        .as_deref()
        .is_some_and(|name| name == "string" || name == "basic_string")
    {
        return TypeRef::String;
    }

    // A handle owns a `shared_ptr<T>` either way, so the C ABI is the same as
    // for a by-value T; only the C++ glue differs.
    if decl_name.as_deref() == Some("shared_ptr") {
        return match template_arg(&ty, 0) {
            Some(inner) => match map_type(inner, types) {
                TypeRef::Object {
                    name,
                    qualified_name,
                    ..
                } => TypeRef::Object {
                    name,
                    qualified_name,
                    shared: true,
                },
                other => TypeRef::Unsupported {
                    name: format!("std::shared_ptr<{}>", other.display_name()),
                },
            },
            None => TypeRef::Unsupported {
                name: ty.get_display_name(),
            },
        };
    }

    if decl_name.as_deref() == Some("optional") {
        return match template_arg(&ty, 0) {
            Some(inner) => {
                let mapped = map_type(inner, types);
                // Absence is a null pointer on the C side, so the payload must
                // be something whose C form is a pointer to begin with.
                if matches!(
                    mapped,
                    TypeRef::String
                        | TypeRef::Object { .. }
                        | TypeRef::Callback { .. }
                        | TypeRef::Struct { .. }
                ) {
                    TypeRef::Optional {
                        inner: Box::new(mapped),
                    }
                } else {
                    TypeRef::Unsupported {
                        name: format!("std::optional<{}>", mapped.display_name()),
                    }
                }
            }
            None => TypeRef::Unsupported {
                name: ty.get_display_name(),
            },
        };
    }

    if decl_name.as_deref() == Some("function") {
        return map_function_type(&ty, types);
    }

    if decl_name.as_deref() == Some("vector") {
        return match template_arg(&ty, 0) {
            Some(element) => {
                let mapped = map_type(element, types);
                // Handles and strings have a C list representation.
                if matches!(mapped, TypeRef::Object { .. } | TypeRef::String) {
                    TypeRef::Vector {
                        element: Box::new(mapped),
                    }
                } else {
                    TypeRef::Unsupported {
                        name: format!("std::vector<{}>", mapped.display_name()),
                    }
                }
            }
            None => TypeRef::Unsupported {
                name: ty.get_display_name(),
            },
        };
    }

    if decl_name.as_deref() == Some("map") {
        let key = template_arg(&ty, 0).map(|arg| map_type(arg, types));
        let value = template_arg(&ty, 1).map(|arg| map_type(arg, types));
        return match (key, value) {
            // Only string -> string maps have a C representation today.
            (Some(TypeRef::String), Some(TypeRef::String)) => TypeRef::Map {
                key: Box::new(TypeRef::String),
                value: Box::new(TypeRef::String),
            },
            (key, value) => TypeRef::Unsupported {
                name: format!(
                    "std::map<{}, {}>",
                    key.map(|ty| ty.display_name()).unwrap_or_else(|| "?".into()),
                    value.map(|ty| ty.display_name()).unwrap_or_else(|| "?".into())
                ),
            },
        };
    }

    let canonical = ty.get_canonical_type();
    let display = canonical.get_display_name();
    let raw_display = ty.get_display_name();
    let normalized = normalize_type_name(&display);
    let raw_normalized = normalize_type_name(&raw_display);

    if normalized == "std::string"
        || normalized == "std::basic_string<char>"
        || raw_normalized == "std::string"
        || raw_normalized == "std::basic_string<char>"
    {
        return TypeRef::String;
    }

    match canonical.get_kind() {
        TypeKind::Void => TypeRef::Void,
        TypeKind::Bool => TypeRef::Bool,
        TypeKind::CharS
        | TypeKind::SChar
        | TypeKind::Short
        | TypeKind::Int
        | TypeKind::Long
        | TypeKind::LongLong
        | TypeKind::UChar
        | TypeKind::UShort
        | TypeKind::UInt
        | TypeKind::ULong
        | TypeKind::ULongLong => TypeRef::Int { name: normalized },
        TypeKind::Float | TypeKind::Double | TypeKind::LongDouble => {
            TypeRef::Float { name: normalized }
        }
        TypeKind::Pointer
            if canonical
                .get_pointee_type()
                .is_some_and(|pointee| pointee.get_canonical_type().get_kind() == TypeKind::Void) =>
        {
            TypeRef::RawPointer
        }
        TypeKind::Pointer
            if canonical.get_pointee_type().is_some_and(|pointee| {
                pointee.is_const_qualified()
                    && matches!(
                        pointee.get_canonical_type().get_kind(),
                        TypeKind::CharS | TypeKind::CharU
                    )
            }) =>
        {
            TypeRef::CString
        }
        // Any other pointer is a borrowed reference with no ownership story:
        // the C side cannot know how long it stays valid, and the handle table
        // only accepts something it can hold a strong reference to.
        TypeKind::Pointer => TypeRef::Unsupported { name: display },
        _ => match lookup_type(&normalized, types).or_else(|| lookup_type(&raw_normalized, types)) {
            Some(entry) => match entry.category {
                TypeCategory::Enum => TypeRef::Enum {
                    name: entry.name.clone(),
                    qualified_name: entry.qualified_name.clone(),
                },
                TypeCategory::Struct => TypeRef::Struct {
                    name: entry.name.clone(),
                    qualified_name: entry.qualified_name.clone(),
                },
                TypeCategory::Class => TypeRef::Object {
                    name: entry.name.clone(),
                    qualified_name: entry.qualified_name.clone(),
                    shared: false,
                },
                // Events only appear inside callback signatures, where they are
                // passed by const reference and never own anything.
                TypeCategory::Event => TypeRef::Struct {
                    name: entry.name.clone(),
                    qualified_name: entry.qualified_name.clone(),
                },
                // Reached only when the alias resolved to something other than
                // an integer, which has no distinct C spelling anyway.
                TypeCategory::Alias => TypeRef::Unsupported { name: display },
            },
            None => TypeRef::Unsupported { name: display },
        },
    }
}

/// The alias entry this type names, if the headers declared one for it.
fn alias_entry<'a>(ty: &Type, types: &'a TypeIndex) -> Option<&'a TypeEntry> {
    let spelling = normalize_type_name(&ty.get_display_name());
    let entry = lookup_type(&spelling, types)?;
    (entry.category == TypeCategory::Alias).then_some(entry)
}

/// Resolves a C++ type spelling against the index, trying the most specific
/// form first: `nativeapi::PositioningStrategy::Type`, then
/// `PositioningStrategy::Type`, then `Type`.
fn lookup_type<'a>(spelling: &str, types: &'a TypeIndex) -> Option<&'a TypeEntry> {
    let trimmed = spelling
        .trim_start_matches("const ")
        .trim()
        .trim_end_matches('*')
        .trim_end_matches('&')
        .trim();
    let without_ns = trimmed.strip_prefix("nativeapi::").unwrap_or(trimmed);
    if let Some(entry) = types.get(without_ns) {
        return Some(entry);
    }
    let short = without_ns.rsplit("::").next()?;
    types.get(short)
}

/// `std::function<void(const WindowEvent&)>` -> a callback taking one event.
/// Only `void` returns cross the ABI: a C callback that has to produce a value
/// would need the binding to marshal it back, which nothing needs yet.
fn map_function_type(ty: &Type, types: &TypeIndex) -> TypeRef {
    let Some(args) = ty.get_template_argument_types() else {
        return TypeRef::Unsupported {
            name: ty.get_display_name(),
        };
    };
    let Some(Some(signature)) = args.first().copied() else {
        return TypeRef::Unsupported {
            name: ty.get_display_name(),
        };
    };
    if signature
        .get_result_type()
        .map(|result| result.get_canonical_type().get_kind() != TypeKind::Void)
        .unwrap_or(true)
    {
        return TypeRef::Unsupported {
            name: ty.get_display_name(),
        };
    }
    let params: Vec<TypeRef> = signature
        .get_argument_types()
        .unwrap_or_default()
        .into_iter()
        .map(|arg| map_type(arg, types))
        .collect();
    if params.iter().any(|param| !param.is_supported()) {
        return TypeRef::Unsupported {
            name: ty.get_display_name(),
        };
    }
    TypeRef::Callback { params }
}

/// Nth template argument of a class template specialization.
fn template_arg<'tu>(ty: &Type<'tu>, index: usize) -> Option<Type<'tu>> {
    ty.get_template_argument_types()?.get(index).copied().flatten()
}

/// Standard-library templates the mapper understands.
const KNOWN_TEMPLATES: &[&str] = &[
    "string",
    "basic_string",
    "shared_ptr",
    "optional",
    "function",
    "vector",
    "map",
];

/// If `ty` names one of the templates we handle — directly or through an alias
/// — returns that name together with the type the template arguments should be
/// read from.
fn template_spelling<'tu>(ty: &Type<'tu>) -> Option<(Option<String>, Type<'tu>)> {
    let direct = type_decl_name(ty);
    if direct
        .as_deref()
        .is_some_and(|name| KNOWN_TEMPLATES.contains(&name))
    {
        return Some((direct, *ty));
    }
    let canonical = ty.get_canonical_type();
    let canonical_name = canonical.get_declaration().and_then(|entity| entity.get_name());
    if canonical_name
        .as_deref()
        .is_some_and(|name| KNOWN_TEMPLATES.contains(&name))
    {
        return Some((canonical_name, canonical));
    }
    None
}

fn type_decl_name(ty: &Type) -> Option<String> {
    ty.get_declaration()
        .and_then(|entity| entity.get_name())
        .or_else(|| {
            ty.get_canonical_type()
                .get_declaration()
                .and_then(|entity| entity.get_name())
        })
}

fn normalize_type_name(name: &str) -> String {
    name.trim()
        .trim_start_matches("const ")
        .trim_end_matches(" const")
        .trim_end_matches('&')
        .trim()
        .to_string()
}

fn entity_file(entity: &Entity) -> Option<PathBuf> {
    entity
        .get_location()
        .and_then(|location| location.get_file_location().file)
        .map(|file| {
            let path = file.get_path();
            path.canonicalize().unwrap_or(path)
        })
}

fn is_from_file(entity: &Entity, header: &Path) -> bool {
    entity_file(entity).is_some_and(|path| path == header)
}

fn is_in_scope(entity: &Entity, scope: &HashSet<PathBuf>) -> bool {
    entity_file(entity).is_some_and(|path| scope.contains(&path))
}

fn entity_tokens_contain_std_string(entity: &Entity) -> bool {
    let tokens = entity
        .get_range()
        .map(|range| {
            range
                .tokenize()
                .into_iter()
                .map(|token| token.get_spelling())
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();

    tokens
        .windows(3)
        .any(|window| window == ["std", "::", "string"])
        || tokens.iter().any(|token| token == "std::string")
}

#[cfg(test)]
mod tests {
    use super::normalize_type_name;

    #[test]
    fn normalizes_const_reference_type_names() {
        assert_eq!(normalize_type_name("const std::string &"), "std::string");
        assert_eq!(
            normalize_type_name("nativeapi::UrlOpenResult"),
            "nativeapi::UrlOpenResult"
        );
    }
}
