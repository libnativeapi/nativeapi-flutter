use std::path::PathBuf;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Api {
    pub headers: Vec<Header>,
    pub diagnostics: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Header {
    pub path: PathBuf,
    pub stem: String,
    pub namespace: String,
    pub enums: Vec<Enum>,
    pub structs: Vec<Struct>,
    pub classes: Vec<Class>,
    /// Integer type aliases (`typedef IdAllocator::IdType WindowId;`). They
    /// carry no behaviour, but dropping them would turn every id in the C ABI
    /// into a bare `unsigned int`.
    #[serde(default)]
    pub aliases: Vec<Alias>,
    /// Event class hierarchies declared by this header. These are not handles:
    /// a whole hierarchy collapses into one tagged C struct.
    #[serde(default)]
    pub events: Vec<EventGroup>,
}

/// A `Event` subtree: one base class plus the concrete events derived from it.
/// Across the C ABI the whole tree is a single discriminated struct, because a
/// callback has to be able to receive any of them through one function pointer.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct EventGroup {
    /// `WindowEvent`
    pub name: String,
    pub qualified_name: String,
    /// Accessors on the base class; every variant carries them.
    pub common: Vec<Field>,
    pub variants: Vec<EventVariant>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct EventVariant {
    /// `WindowFocusedEvent`
    pub name: String,
    pub qualified_name: String,
    /// The part of the name that distinguishes it: `Focused`.
    pub discriminant: String,
    /// Accessors this variant adds on top of the group's common fields.
    pub fields: Vec<Field>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Alias {
    pub name: String,
    pub qualified_name: String,
    pub underlying: TypeRef,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Enum {
    pub name: String,
    pub qualified_name: String,
    pub variants: Vec<EnumVariant>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct EnumVariant {
    pub name: String,
    pub value: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Struct {
    pub name: String,
    pub qualified_name: String,
    pub fields: Vec<Field>,
    /// Static factory helpers (`Color::FromHex`) and const value accessors
    /// (`Color::ToRGBA`). Plain data structs have none.
    #[serde(default)]
    pub methods: Vec<Method>,
    /// Static const members of the struct's own type (`Color::Black`).
    #[serde(default)]
    pub constants: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Field {
    pub name: String,
    pub ty: TypeRef,
}

/// How a C++ class is exposed across the C ABI.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum ClassKind {
    /// `static T& GetInstance()`; methods become free functions without a
    /// receiver argument.
    Singleton,
    /// Regular class; instances are exposed as opaque handles and every method
    /// takes the handle as its first argument.
    Instance,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Class {
    pub name: String,
    pub qualified_name: String,
    pub kind: ClassKind,
    /// Class derives from `NativeObjectProvider`, so it also exposes
    /// `GetNativeObject()`.
    pub native_object: bool,
    /// Public constructors, excluding copy/move. Only instance classes can be
    /// constructed across the ABI.
    pub constructors: Vec<Constructor>,
    pub methods: Vec<Method>,
    /// Event type this class emits (`EventEmitter<WindowEvent>` -> `WindowEvent`),
    /// which turns into listener registration functions across the ABI.
    #[serde(default)]
    pub event: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Constructor {
    pub params: Vec<Param>,
}

impl Constructor {
    /// Suffix distinguishing overloads: the default constructor has none,
    /// others are named after their parameters (`with_scope`).
    pub fn overload_suffix(&self) -> Option<String> {
        if self.params.is_empty() {
            return None;
        }
        Some(format!(
            "with_{}",
            self.params
                .iter()
                .map(|param| param.name.as_str())
                .collect::<Vec<_>>()
                .join("_and_")
        ))
    }
}

impl Class {
    pub fn is_singleton(&self) -> bool {
        matches!(self.kind, ClassKind::Singleton)
    }

    pub fn is_instance(&self) -> bool {
        matches!(self.kind, ClassKind::Instance)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Method {
    pub name: String,
    pub return_type: TypeRef,
    pub params: Vec<Param>,
    pub is_const: bool,
    pub is_static: bool,
}

impl Method {
    /// A const, argument-less `GetX` / `IsX` / `HasX` method, which bindings
    /// expose as a property (Swift) or a bare accessor (Rust).
    pub fn is_accessor(&self) -> bool {
        self.is_const
            && !self.is_static
            && self.params.is_empty()
            && !matches!(self.return_type, TypeRef::Void)
            && (self.accessor_stem().is_some()
                || self.name.starts_with("Is")
                || self.name.starts_with("Has"))
    }

    /// `GetWorkArea` -> `WorkArea`; `IsPrimary` -> `IsPrimary`.
    pub fn accessor_stem(&self) -> Option<&str> {
        self.name
            .strip_prefix("Get")
            .filter(|rest| !rest.is_empty() && rest.starts_with(char::is_uppercase))
    }

    /// The name bindings should use: accessors drop the `Get` prefix.
    pub fn binding_name(&self) -> &str {
        if self.is_accessor() {
            self.accessor_stem().unwrap_or(&self.name)
        } else {
            &self.name
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Param {
    pub name: String,
    pub ty: TypeRef,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum TypeRef {
    Void,
    Bool,
    Int {
        name: String,
    },
    Float {
        name: String,
    },
    String,
    /// A raw `const char*` in the C++ signature. Identical to `String` in C, but
    /// the glue passes the pointer straight through instead of building a
    /// `std::string` the callee cannot accept.
    CString,
    Enum {
        name: String,
        qualified_name: String,
    },
    Struct {
        name: String,
        qualified_name: String,
    },
    /// A named integer alias declared by one of the headers. Behaves exactly
    /// like `underlying` everywhere except in the spelling of the C type.
    Alias {
        name: String,
        underlying: Box<TypeRef>,
    },
    /// An instance of a class exposed as an opaque handle.
    Object {
        name: String,
        qualified_name: String,
        /// The C++ signature spells this as `std::shared_ptr<T>`. The C ABI is
        /// identical either way — a handle table slot owns a `shared_ptr<T>`
        /// regardless — but the glue differs: a shared type is stored as-is,
        /// a by-value one is copied into a fresh `shared_ptr` first.
        #[serde(default)]
        shared: bool,
    },
    /// `std::vector<T>`; supports handles and strings.
    Vector {
        element: Box<TypeRef>,
    },
    /// `std::map<K, V>`; only `map<string, string>` is currently supported.
    Map {
        key: Box<TypeRef>,
        value: Box<TypeRef>,
    },
    /// `std::optional<T>`; the C ABI represents absence as a null pointer, so
    /// only types whose C form is a pointer can be wrapped.
    Optional {
        inner: Box<TypeRef>,
    },
    /// `std::function<void(...)>`; crosses the ABI as a function pointer plus
    /// an opaque `user_data`.
    Callback {
        params: Vec<TypeRef>,
    },
    /// Opaque platform pointer (`void*`).
    RawPointer,
    Unsupported {
        name: String,
    },
}

impl TypeRef {
    pub fn display_name(&self) -> String {
        match self {
            TypeRef::Void => "void".to_string(),
            TypeRef::Bool => "bool".to_string(),
            TypeRef::Int { name } => name.clone(),
            TypeRef::Float { name } => name.clone(),
            TypeRef::String => "std::string".to_string(),
            TypeRef::CString => "const char*".to_string(),
            TypeRef::Alias { name, .. } => name.clone(),
            TypeRef::Enum { name, .. } => name.clone(),
            TypeRef::Struct { name, .. } => name.clone(),
            TypeRef::Object { name, .. } => name.clone(),
            TypeRef::Vector { element } => format!("std::vector<{}>", element.display_name()),
            TypeRef::Map { key, value } => {
                format!("std::map<{}, {}>", key.display_name(), value.display_name())
            }
            TypeRef::Optional { inner } => format!("std::optional<{}>", inner.display_name()),
            TypeRef::Callback { params } => format!(
                "std::function<void({})>",
                params
                    .iter()
                    .map(|param| param.display_name())
                    .collect::<Vec<_>>()
                    .join(", ")
            ),
            TypeRef::RawPointer => "void*".to_string(),
            TypeRef::Unsupported { name } => name.clone(),
        }
    }

    pub fn is_supported(&self) -> bool {
        match self {
            TypeRef::Unsupported { .. } => false,
            TypeRef::Vector { element } => element.is_supported(),
            TypeRef::Map { key, value } => key.is_supported() && value.is_supported(),
            TypeRef::Optional { inner } => inner.is_supported(),
            TypeRef::Alias { underlying, .. } => underlying.is_supported(),
            TypeRef::Callback { params } => params.iter().all(TypeRef::is_supported),
            _ => true,
        }
    }

    /// Name of the user-defined type this reference points at, if any. Used to
    /// resolve cross-header dependencies.
    pub fn named_type(&self) -> Option<&str> {
        match self {
            TypeRef::Enum { name, .. } | TypeRef::Struct { name, .. } => Some(name),
            TypeRef::Object { name, .. } | TypeRef::Alias { name, .. } => Some(name),
            TypeRef::Vector { element } => element.named_type(),
            TypeRef::Optional { inner } => inner.named_type(),
            TypeRef::Map { .. } => None,
            _ => None,
        }
    }

    /// Every named type reachable from this reference. Unlike `named_type`,
    /// this descends into callback parameter lists, which carry types no other
    /// part of the signature mentions.
    pub fn named_types(&self) -> Vec<&str> {
        match self {
            TypeRef::Callback { params } => {
                params.iter().flat_map(TypeRef::named_types).collect()
            }
            other => other.named_type().into_iter().collect(),
        }
    }

    /// Strips `std::optional` so callers can reason about the payload type.
    pub fn unwrap_optional(&self) -> &TypeRef {
        match self {
            TypeRef::Optional { inner } => inner.unwrap_optional(),
            other => other,
        }
    }
}
