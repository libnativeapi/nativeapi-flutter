use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use anyhow::{Context, Result};
use clap::Parser;

use codegen_shared::ir::serializer;
use codegen_shared::{naming, resolve_repo_root, write_files};

mod csharp;
mod dart;
mod js;
mod python;
mod rust;

#[derive(Debug, Parser)]
#[command(name = "codegen-bindings")]
#[command(about = "Generate Rust/Dart/C#/JS/Python FFI bindings from the IR emitted by codegen-capi.")]
struct CliArgs {
    /// Path to the IR JSON emitted by `codegen-capi --emit-ir`.
    #[arg(long)]
    ir: PathBuf,

    /// Path to the core (nativeapi) repository root. Used to mirror header
    /// sub-paths (e.g. foundation/) into the Swift output tree; must be the
    /// same repo the IR was parsed from.
    #[arg(long, default_value = ".")]
    repo: PathBuf,

    /// Path to the nativeapi-rust repository. Rust bindings are skipped when
    /// this is absent.
    #[arg(long)]
    rust: Option<PathBuf>,

    /// Path to the Dart binding (bindings/dart). Dart bindings are skipped
    /// when this is absent.
    #[arg(long)]
    dart: Option<PathBuf>,

    /// Path to the nativeapi-csharp repository. C# bindings are skipped when
    /// this is absent.
    #[arg(long)]
    csharp: Option<PathBuf>,

    /// Path to the JS/TS binding (bindings/js). JS bindings are skipped when
    /// this is absent.
    #[arg(long)]
    js: Option<PathBuf>,

    /// Path to the Python binding (bindings/python). Python bindings are
    /// skipped when this is absent.
    #[arg(long)]
    python: Option<PathBuf>,

    /// Verify that generated files are up to date without writing anything.
    /// Exits non-zero when any file would change.
    #[arg(long)]
    check: bool,
}

/// `to` relative to `from`, `/`-separated, for paths written into generated files.
fn relative_path(from: &Path, to: &Path) -> String {
    let from = from.canonicalize().unwrap_or_else(|_| from.to_path_buf());
    let to = to.canonicalize().unwrap_or_else(|_| to.to_path_buf());
    let from: Vec<_> = from.components().collect();
    let to: Vec<_> = to.components().collect();
    let common = from.iter().zip(&to).take_while(|(a, b)| a == b).count();
    let mut parts: Vec<String> = vec!["..".to_string(); from.len() - common];
    parts.extend(
        to[common..]
            .iter()
            .map(|c| c.as_os_str().to_string_lossy().into_owned()),
    );
    parts.join("/")
}

fn main() -> Result<()> {
    let args = CliArgs::parse();

    let repo_root = resolve_repo_root(&args.repo)?;
    let src_dir = repo_root.join("src");
    let prefix = "native_";

    let rust_out = binding_out(args.rust.as_deref(), "nativeapi/src");
    let dart_out = binding_out(args.dart.as_deref(), "nativeapi/lib/src");
    let csharp_out = binding_out(args.csharp.as_deref(), "src");
    let js_out = args.js.clone();
    let python_out = binding_out(args.python.as_deref(), "nativeapi");

    report_binding("rust", &rust_out);
    report_binding("dart", &dart_out);
    report_binding("csharp", &csharp_out);
    report_binding("js", &js_out);
    report_binding("python", &python_out);

    let json = std::fs::read_to_string(&args.ir)
        .with_context(|| format!("failed to read IR from {}", args.ir.display()))?;
    let api = serializer::from_json_string(&json)?;

    eprintln!("  generating bindings...");
    let origins = naming::type_origins(&api);
    let mut files = Vec::new();
    if let Some(out) = &rust_out {
        files.push(rust::generate_modules(&api, &origins, out));
    }
    if let Some(out) = &dart_out {
        files.push(dart::generate_barrel(&api, out));
        files.push(dart::generate_support(out));
        files.push(dart::generate_callbacks(out));
    }
    if let Some(out) = &csharp_out {
        files.push(csharp::generate_support(out));
    }
    if let Some(out) = &js_out {
        files.extend(js::generate_shared(&api, out, prefix));
    }
    if let Some(out) = &python_out {
        files.extend(python::generate_shared(&api, out, prefix));
    }
    if let Some(dart_repo) = &args.dart {
        let cnativeapi_root = dart_repo.join("cnativeapi");
        let core_rel = relative_path(&cnativeapi_root, &repo_root);
        files.push(dart::generate_ffigen_config(
            &api,
            &cnativeapi_root,
            &core_rel,
        ));
    }
    for header in &api.headers {
        // C# mirrors the source tree, so `foundation/geometry.h` lands in
        // `src/NativeAPI/Foundation/`. Derived from the header's own path
        // rather than from its position in API_HEADERS, which stops matching
        // once event headers are folded away.
        let subdir = header
            .path
            .strip_prefix(&src_dir)
            .ok()
            .and_then(|relative| relative.parent())
            .filter(|parent| !parent.as_os_str().is_empty());

        if let Some(out) = &rust_out {
            files.push(rust::generate(&api, header, &origins, out, prefix));
        }
        if let Some(out) = &dart_out {
            files.push(dart::generate(&api, header, &origins, out, prefix));
        }
        if let Some(out) = &csharp_out {
            files.extend(csharp::generate(
                &api, header, &origins, out, prefix, subdir,
            ));
        }
        if let Some(out) = &js_out {
            files.extend(js::generate(&api, header, &origins, out, prefix));
        }
        if let Some(out) = &python_out {
            files.push(python::generate(&api, header, &origins, out, prefix));
        }
    }

    // Format before both writing and checking, so generation and Dart CI
    // agree and --check remains read-only. Keep hand-written files untouched.
    for file in &mut files {
        if file.path.extension().is_some_and(|ext| ext == "dart") {
            file.contents = format_dart(&file.path, &file.contents)?;
        }
    }
    write_files(&files, args.check)
}

fn format_dart(path: &Path, source: &str) -> Result<String> {
    let mut child = Command::new("dart")
        .args([
            "format",
            "--output=show",
            "--summary=none",
            "--language-version=3.9",
            "--stdin-name",
        ])
        .arg(path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .context("Dart SDK is required to format generated Dart bindings")?;
    let mut stdin = child.stdin.take().expect("piped stdin");
    let source = source.to_owned();
    // Drain stdout concurrently with feeding stdin, including large modules.
    let writer = std::thread::spawn(move || stdin.write_all(source.as_bytes()));
    let output = child.wait_with_output()?;
    writer
        .join()
        .map_err(|_| anyhow::anyhow!("formatter input thread failed"))??;
    anyhow::ensure!(
        output.status.success(),
        "dart format failed for {}: {}",
        path.display(),
        String::from_utf8_lossy(&output.stderr)
    );
    String::from_utf8(output.stdout).context("Dart formatter returned invalid UTF-8")
}

/// Output directory inside a binding repo, or `None` when the repo was not
/// given.
fn binding_out(repo: Option<&Path>, subdir: &str) -> Option<PathBuf> {
    repo.map(|repo| repo.join(subdir))
}

fn report_binding(lang: &str, out: &Option<PathBuf>) {
    match out {
        Some(path) => eprintln!("  {lang:<11} {}", path.display()),
        None => eprintln!("  {lang:<11} (skipped)"),
    }
}
