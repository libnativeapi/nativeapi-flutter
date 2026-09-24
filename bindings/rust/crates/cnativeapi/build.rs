use cmake::Config;
use std::env;
use std::path::PathBuf;

fn main() {
    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();
    let _target_arch = env::var("CARGO_CFG_TARGET_ARCH").unwrap();

    println!("cargo:rerun-if-changed=cxx_impl/src");
    println!("cargo:rerun-if-changed=cxx_impl/include");
    println!("cargo:rerun-if-changed=cxx_impl/CMakeLists.txt");

    // Configure CMake build
    let mut cmake_config = Config::new("cxx_impl");

    let profile = cmake_config.get_profile().to_owned();

    // Platform-specific configurations
    match target_os.as_str() {
        "macos" => {
            cmake_config.define("CMAKE_SYSTEM_NAME", "Darwin");
            // Mirrors src/CMakeLists.txt. Cocoa alone leaves the global
            // shortcut and launch-at-login implementations unresolved: hotkeys
            // go through Carbon's RegisterEventHotKey, and login items through
            // SMAppService.
            println!("cargo:rustc-link-lib=framework=Cocoa");
            println!("cargo:rustc-link-lib=framework=QuartzCore");
            println!("cargo:rustc-link-lib=framework=Carbon");
            println!("cargo:rustc-link-lib=framework=ServiceManagement");
        }
        "ios" => {
            cmake_config.define("CMAKE_SYSTEM_NAME", "iOS");
            println!("cargo:rustc-link-lib=framework=UIKit");
            println!("cargo:rustc-link-lib=framework=Foundation");
            println!("cargo:rustc-link-lib=framework=CoreGraphics");
        }
        "linux" => {
            cmake_config.define("CMAKE_SYSTEM_NAME", "Linux");
            // Note: Linux dependencies (GTK, X11, etc.) should be installed on the system
            for library in ["gtk+-3.0", "x11", "xi"] {
                pkg_config::Config::new().probe(library).unwrap();
            }
            println!("cargo:rustc-link-lib=pthread");
        }
        "windows" => {
            println!("cargo:rustc-link-lib=user32");
            println!("cargo:rustc-link-lib=shell32");
            println!("cargo:rustc-link-lib=dwmapi");
            println!("cargo:rustc-link-lib=gdiplus");
            println!("cargo:rustc-link-lib=crypt32");
            for library in ["comctl32", "advapi32", "version", "ole32", "uuid", "gdi32"] {
                println!("cargo:rustc-link-lib={library}");
            }
        }
        "android" => {
            cmake_config.define("ANDROID", "ON");
            println!("cargo:rustc-link-lib=log");
            println!("cargo:rustc-link-lib=android");
        }
        _ => {
            println!("cargo:warning=Unsupported target OS: {}", target_os);
        }
    }

    // Build the library with CMake, using build target instead of install
    let dst = cmake_config.build_target("nativeapi").build();

    // Tell cargo where to find the compiled library
    // The actual library file is libnativeapi.a in build/src/
    let build_dir = dst.join("build");
    let src_dir = build_dir.join("src");

    println!("cargo:rustc-link-search=native={}", src_dir.display());
    // Visual Studio generators put artifacts in Debug/Release below src/.
    println!(
        "cargo:rustc-link-search=native={}",
        src_dir.join(profile).display()
    );

    // Link the static library - note the library is named libnativeapi.a, not libnativeapi.a
    // So we need to link it as "nativeapi" (without the "lib" prefix and ".a" suffix)
    println!("cargo:rustc-link-lib=static=nativeapi");

    // On macOS and iOS, we also need to link against libc++
    if target_os == "macos" || target_os == "ios" {
        println!("cargo:rustc-link-lib=c++");
    }

    // On Linux, we need to link against libstdc++
    if target_os == "linux" {
        println!("cargo:rustc-link-lib=stdc++");
    }

    // Generate bindings (optional - we'll create them manually for better control)
    let bindings_path = PathBuf::from(env::var("OUT_DIR").unwrap()).join("bindings.rs");

    // For now, we'll create a simple binding file that includes the C API
    std::fs::write(
        bindings_path,
        r#"// Auto-generated bindings placeholder
// Include the C API headers and create Rust bindings manually in lib.rs
"#,
    )
    .expect("Could not write bindings file");
}
