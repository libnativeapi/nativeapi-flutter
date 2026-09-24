use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use anyhow::{Context, Result};
use clap::Parser;

use codegen_shared::ir::serializer;
use codegen_shared::{naming, resolve_repo_root, write_files};

mod csharp;
mod dart;
mod rust;

#[derive(Debug, Parser)]
#[command(name = "codegen-bindings")]
#[command(about = "Generate Rust/Swift/Dart FFI bindings from the IR emitted by codegen-capi.")]
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

    /// Path to the nativeapi-flutter repository. Dart bindings are skipped
    /// when this is absent.
    #[arg(long)]
    dart: Option<PathBuf>,

    /// Path to the nativeapi-csharp repository. C# bindings are skipped when
    /// this is absent.
    #[arg(long)]
    csharp: Option<PathBuf>,

    /// Verify that generated files are up to date without writing anything.
    /// Exits non-zero when any file would change.
    #[arg(long)]
    check: bool,
}

fn main() -> Result<()> {
    let args = CliArgs::parse();

    let repo_root = resolve_repo_root(&args.repo)?;
    let src_dir = repo_root.join("src");
    let prefix = "native_";

    let rust_out = binding_out(args.rust.as_deref(), "crates/nativeapi/src");
    let dart_out = binding_out(args.dart.as_deref(), "packages/nativeapi/lib/src");
    let csharp_out = binding_out(args.csharp.as_deref(), "src");

    report_binding("rust", &rust_out);
    report_binding("dart", &dart_out);
    report_binding("csharp", &csharp_out);

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
    }
    if let Some(out) = &csharp_out {
        files.push(csharp::generate_support(out));
    }
    if let Some(dart_repo) = &args.dart {
        files.push(dart::generate_ffigen_config(
            &api,
            &dart_repo.join("packages/cnativeapi"),
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
    }

    // Format before both writing and checking, so generation and Flutter CI
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
        .context("Dart SDK is required to format generated Flutter bindings")?;
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
