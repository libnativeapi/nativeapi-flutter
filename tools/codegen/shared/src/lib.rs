pub mod ir;
pub mod naming;
pub mod parser;

use std::fs;
use std::path::PathBuf;

use anyhow::{bail, Context, Result};

/// C++ header files to generate bindings for. Ordered roughly by dependency so
/// the generated includes read top-down; the generator itself does not care.
pub const API_HEADERS: &[&str] = &[
    "foundation/geometry.h",
    "foundation/color.h",
    "foundation/keyboard.h",
    "placement.h",
    "dialog.h",
    "accessibility_manager.h",
    "display.h",
    "display_manager.h",
    "url_opener.h",
    "app_info.h",
    "device_info.h",
    "preferences.h",
    "secure_storage.h",
    "launch_at_login.h",
    "message_dialog.h",
    "file_dialog.h",
    "notification_manager.h",
    "image.h",
    "window_shape.h",
    "window_shadow.h",
    "window.h",
    "window_manager.h",
    "window_drag_session.h",
    "drag_source.h",
    "drop_target.h",
    "positioning_strategy.h",
    "menu.h",
    "tray_icon.h",
    "tray_manager.h",
    "shortcut.h",
    "shortcut_manager.h",
    "keyboard_monitor.h",
    "application.h",
];

#[derive(Debug, Clone)]
pub struct GeneratedFile {
    pub path: PathBuf,
    pub contents: String,
}

/// Text of the first line of every file this tool owns, minus the comment
/// marker. It is what makes overwriting a file safe.
pub const GENERATED_BANNER: &str = "AUTO-GENERATED. DO NOT EDIT.";

/// Whether `contents` carries the generated banner, in any of the comment
/// syntaxes the outputs use (`//` for C-likes, `#` for YAML).
fn is_generated(contents: &str) -> bool {
    let first = contents.lines().next().unwrap_or_default().trim_start();
    for marker in ["//", "#"] {
        if let Some(rest) = first.strip_prefix(marker) {
            if rest.trim_start().starts_with(GENERATED_BANNER) {
                return true;
            }
        }
    }
    false
}

/// What happened to one file.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Written {
    /// Written, or verified identical in check mode.
    Ok,
    /// Left alone: a hand-written file already occupies that path.
    SkippedHandWritten,
}

/// Write a generated file to disk, or verify it matches existing content in
/// check mode.
///
/// A file that already exists without the generated banner is never touched.
/// The binding generators share their output directories with hand-written code
/// — `Sources/NativeAPI/` holds both — so adding a header to `API_HEADERS`
/// would otherwise silently replace someone's hand-written wrapper. Opting a
/// module in is therefore explicit: delete the hand-written file first.
pub fn write_or_check(file: &GeneratedFile, check: bool) -> Result<Written> {
    let existing = fs::read_to_string(&file.path).ok();
    if let Some(existing) = &existing {
        if !is_generated(existing) {
            return Ok(Written::SkippedHandWritten);
        }
    }

    if check {
        let existing =
            existing.with_context(|| format!("{} does not exist", file.path.display()))?;
        if existing.replace("\r\n", "\n") != file.contents.replace("\r\n", "\n") {
            bail!("{} is not up to date", file.path.display());
        }
        return Ok(Written::Ok);
    }

    if let Some(parent) = file.path.parent() {
        fs::create_dir_all(parent)
            .with_context(|| format!("failed to create {}", parent.display()))?;
    }
    fs::write(&file.path, &file.contents)
        .with_context(|| format!("failed to write {}", file.path.display()))?;
    Ok(Written::Ok)
}

/// Write (or, in check mode, verify) a batch of generated files, reporting
/// skipped hand-written files and failing when anything is out of date.
pub fn write_files(files: &[GeneratedFile], check: bool) -> Result<()> {
    let mut stale = Vec::new();
    let mut skipped = Vec::new();
    let mut written = 0usize;
    for file in files {
        match write_or_check(file, check) {
            Ok(Written::Ok) => written += 1,
            Ok(Written::SkippedHandWritten) => skipped.push(file.path.clone()),
            Err(err) => {
                if !check {
                    return Err(err);
                }
                stale.push(err);
            }
        }
    }

    for path in &skipped {
        eprintln!(
            "warning: kept hand-written {} (delete it to switch to the generated version)",
            path.display()
        );
    }

    if !stale.is_empty() {
        for err in &stale {
            eprintln!("error: {err}");
        }
        bail!("{} generated file(s) out of date", stale.len());
    }

    let suffix = if skipped.is_empty() {
        String::new()
    } else {
        format!(", {} hand-written file(s) kept", skipped.len())
    };
    if check {
        eprintln!("  ✓ {written} file(s) up to date{suffix}");
    } else {
        eprintln!("  ✓ done ({written} files{suffix})");
    }

    Ok(())
}

/// Resolve a possibly-relative path against the current directory and
/// canonicalize it.
pub fn resolve_repo_root(path: &std::path::Path) -> Result<PathBuf> {
    let resolved = if path.is_absolute() {
        path.to_path_buf()
    } else {
        let cwd = std::env::current_dir()
            .map_err(|e| anyhow::anyhow!("cannot determine current directory: {e}"))?;
        cwd.join(path)
    };
    Ok(std::fs::canonicalize(&resolved)
        .with_context(|| format!("failed to canonicalize {}", resolved.display()))?)
}

/// Resolve a possibly-relative path against the current directory without
/// requiring it to exist.
pub fn resolve_cwd_path(path: &std::path::Path) -> PathBuf {
    if path.is_absolute() {
        path.to_path_buf()
    } else {
        std::env::current_dir()
            .map(|cwd| cwd.join(path))
            .unwrap_or_else(|_| path.to_path_buf())
    }
}
