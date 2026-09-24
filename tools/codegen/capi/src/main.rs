use std::path::PathBuf;

use anyhow::Result;
use clap::Parser;

use codegen_shared::ir::serializer;
use codegen_shared::{parser, resolve_cwd_path, resolve_repo_root, write_files, API_HEADERS};

mod generator;

#[derive(Debug, Parser)]
#[command(name = "codegen-capi")]
#[command(about = "Generate the C ABI and umbrella header from nativeapi C++ headers.")]
struct CliArgs {
    /// Path to the core (nativeapi) repository root.
    #[arg(long, default_value = ".")]
    repo: PathBuf,

    /// Write the parsed IR as JSON to this path. Always written, even in
    /// --check mode; codegen-bindings consumes it.
    #[arg(long)]
    emit_ir: Option<PathBuf>,

    /// Parse headers and emit IR only, generating no C ABI files.
    #[arg(long, requires = "emit_ir")]
    parse_only: bool,

    /// Verify that generated files are up to date without writing anything.
    /// Exits non-zero when any file would change.
    #[arg(long)]
    check: bool,
}

fn main() -> Result<()> {
    let args = CliArgs::parse();

    let repo_root = resolve_repo_root(&args.repo)?;
    let src_dir = repo_root.join("src");
    let headers: Vec<_> = API_HEADERS.iter().map(|name| src_dir.join(name)).collect();
    let includes = vec![src_dir.clone(), repo_root.join("include")];
    let capi_dir = src_dir.join("capi");
    let prefix = "native_";

    eprintln!("  repo        {}", repo_root.display());
    eprintln!("  parsing headers...");
    let api = parser::parse(&headers, &includes)?;

    if let Some(path) = &args.emit_ir {
        let path = resolve_cwd_path(path);
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(&path, serializer::to_json_string(&api)?)?;
    }

    for diagnostic in &api.diagnostics {
        eprintln!("warning: {diagnostic}");
    }

    if args.parse_only {
        return Ok(());
    }

    eprintln!("  generating C ABI...");
    let origins = codegen_shared::naming::type_origins(&api);
    let mut files = vec![
        generator::generate_common(&capi_dir, prefix),
        generator::generate_umbrella(&api, &repo_root.join("include"), &capi_dir),
    ];
    for header in &api.headers {
        files.extend(generator::generate(&api, header, &origins, &capi_dir, prefix));
    }

    write_files(&files, args.check)
}
