#!/usr/bin/env python3
"""
Script to regenerate bindings by:
1. Pulling latest cxx_impl submodule
2. Updating macos/cnativeapi/Sources/cnativeapi/cnativeapi.mm include statements
3. Updating ios/cnativeapi/Sources/cnativeapi/cnativeapi.mm include statements
4. Updating macos/cnativeapi/Sources/cnativeapi/include/cnativeapi.h
5. Updating ios/cnativeapi/Sources/cnativeapi/include/cnativeapi.h
6. Updating ffigen.yaml with all C API header files
7. Generating bindings with ffigen
"""

import os
import re
import subprocess
import sys
from pathlib import Path
import argparse


def run_command(cmd, cwd=None):
    """Run a shell command and return success status."""
    print(f"Running: {' '.join(cmd)}")
    try:
        result = subprocess.run(
            cmd, cwd=cwd, check=True, capture_output=True, text=True
        )
        if result.stdout:
            print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        if e.stderr:
            print(f"Error output: {e.stderr}")
        return False


def update_cxx_impl():
    """Update cxx_impl submodule to latest."""
    print("\nStep 1/5: Updating cxx_impl submodule")
    print("Pulling latest changes from cxx_impl submodule...")

    script_dir = Path(__file__).parent
    repo_root = script_dir.parent.parent

    # Update submodule
    if not run_command(
        ["git", "submodule", "update", "--remote", "packages/cnativeapi/cxx_impl"],
        cwd=repo_root,
    ):
        print("Warning: Failed to update cxx_impl submodule")
        return False

    print("Submodule updated successfully")
    return True


def find_capi_headers(cxx_impl_dir):
    """Find all C API header files (*_c.h) in cxx_impl/src/capi."""
    capi_dir = cxx_impl_dir / "src" / "capi"
    if not capi_dir.exists():
        return []

    headers = []
    for header_file in capi_dir.glob("*_c.h"):
        # Use relative path from packages/cnativeapi
        rel_path = f"cxx_impl/src/capi/{header_file.name}"
        headers.append(rel_path)

    return sorted(headers)


def find_cpp_headers(cxx_impl_dir):
    """Find all C++ API header files (*.h) in cxx_impl/src, excluding capi/ and platform/."""
    src_dir = cxx_impl_dir / "src"
    if not src_dir.exists():
        return []

    headers = []
    # Find all .h files in src/ and subdirectories, excluding capi/ and platform/
    for header_file in src_dir.rglob("*.h"):
        file_str = str(header_file)
        # Skip capi/ and platform/ directories
        if "/capi/" in file_str or "/platform/" in file_str:
            continue
        # Calculate relative path from cnativeapi.h location
        # cnativeapi.h is at packages/cnativeapi/{platform}/cnativeapi/Sources/cnativeapi/include/
        # cxx_impl is at packages/cnativeapi/cxx_impl/
        # So relative path should be ../../../../../cxx_impl/src/...
        rel_path = os.path.relpath(header_file, cxx_impl_dir.parent)
        headers.append((rel_path, header_file))

    # Sort by path for consistent ordering
    headers.sort(key=lambda x: x[0])
    return [h[0] for h in headers]


def update_cnativeapi_h(header_path, cxx_impl_dir):
    """Update cnativeapi.h file with C++ and C API header includes."""
    print(f"Updating {header_path.name}...")

    # Find all C++ API headers (returns paths relative to cxx_impl_dir.parent)
    cpp_headers = find_cpp_headers(cxx_impl_dir)
    print(f"  Found {len(cpp_headers)} C++ API headers")

    # Find all C API headers (returns paths relative to cxx_impl_dir.parent)
    capi_headers = find_capi_headers(cxx_impl_dir)
    print(f"  Found {len(capi_headers)} C API headers")

    # Calculate relative path from header_path to cxx_impl_dir
    # header_path is at packages/cnativeapi/{platform}/cnativeapi/Sources/cnativeapi/include/
    # cxx_impl_dir is at packages/cnativeapi/cxx_impl/
    cxx_impl_rel = os.path.relpath(cxx_impl_dir, header_path.parent)

    # Generate C++ includes
    cpp_includes = []
    for header in cpp_headers:
        # header is like "cxx_impl/src/accessibility_manager.h"
        # Need to convert to relative path from header_path
        # Join cxx_impl_rel with the part after "cxx_impl/"
        if header.startswith("cxx_impl/"):
            rel_path = os.path.join(cxx_impl_rel, header[len("cxx_impl/"):])
        else:
            rel_path = os.path.join(cxx_impl_rel, "src", header)
        # Normalize path separators
        rel_path = rel_path.replace("\\", "/")
        cpp_includes.append(f'#include "{rel_path}"')

    # Generate C API includes
    capi_includes = []
    for header in capi_headers:
        # header is like "cxx_impl/src/capi/accessibility_manager_c.h"
        # Need to convert to relative path from header_path
        if header.startswith("cxx_impl/"):
            rel_path = os.path.join(cxx_impl_rel, header[len("cxx_impl/"):])
        else:
            rel_path = os.path.join(cxx_impl_rel, "src", "capi", header)
        # Normalize path separators
        rel_path = rel_path.replace("\\", "/")
        capi_includes.append(f'#include "{rel_path}"')

    # Generate header file content
    content = "#pragma once\n\n"
    content += "#ifdef __cplusplus\n"
    content += "// C++ API headers\n"
    content += "\n".join(cpp_includes) + "\n"
    content += "#endif\n\n"
    content += "// C API headers (available for both C and C++)\n"
    content += "\n".join(capi_includes) + "\n"

    # Write header file
    with open(header_path, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"  Updated {header_path.name} successfully")
    return True


def update_ffigen_yaml(ffigen_path, capi_headers):
    """Update ffigen.yaml with all C API header files."""
    print("\nStep 6/7: Updating ffigen configuration")
    print(f"Found {len(capi_headers)} C API header files to process...")

    with open(ffigen_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Find entry-points section
    # Format: entry-points:\n    - "..."\n    - "..."
    # Don't include the trailing newline and "include-directives:" in the match
    entry_points_pattern = (
        r"(entry-points:\n)((?:    - .*\n)*)(?=\n  include-directives:)"
    )
    entry_match = re.search(entry_points_pattern, content)

    # Find include-directives section
    # Format: include-directives:\n    - "..."\n    - "..."\n\npreamble: |
    # Allow flexible whitespace between list and preamble
    include_directives_pattern = (
        r"(include-directives:\n)((?:    - .*\n)+)(\n+preamble:)"
    )
    include_match = re.search(include_directives_pattern, content)

    if not entry_match or not include_match:
        print("Error: Could not parse ffigen.yaml")
        if not entry_match:
            print("  - Missing 'entry-points' section")
        if not include_match:
            print("  - Missing 'include-directives' section")
        return False

    # Generate new entries
    new_entries = []
    for header in capi_headers:
        new_entries.append(f'    - "{header}"')

    # Replace entry-points section: preserve the format with trailing newline
    # entry_match.group(2) may end with '\n' (from last list item)
    # We need to add a newline before "  include-directives:"
    new_entry_section = entry_match.group(1) + "\n".join(new_entries) + "\n"

    # Replace include-directives section: preserve the format with trailing newlines before preamble
    # group(2) ends with '\n' (from last list item), group(3) starts with '\n'
    # So we need to ensure the new list also ends with '\n' before appending group(3)
    # Build the list part only (without "include-directives:" header)
    new_include_list = "\n".join(new_entries) + "\n" + include_match.group(3)

    # Replace sections
    # entry_match ends before "\n  include-directives:", include_match starts at "include-directives:"
    # So we need to add "\n  include-directives:" before the new list
    new_content = (
        content[: entry_match.start()]
        + new_entry_section
        + "\n  include-directives:"
        + "\n"  # Add the "  include-directives:" header with newline
        + new_include_list  # Add the list items and preamble
        + content[include_match.end() :]
    )

    with open(ffigen_path, "w", encoding="utf-8") as f:
        f.write(new_content)

    print(f"Configuration updated with {len(capi_headers)} header files")
    for header in capi_headers:
        print(f"  - {header}")
    return True


def find_source_files(cxx_impl_dir, platform):
    """Find all source files (.cpp and .mm) needed for the specified platform."""
    src_dir = cxx_impl_dir / "src"
    source_files = []

    # Find all C++ and Objective-C++ files
    for ext in ["*.cpp", "*.mm"]:
        source_files.extend(src_dir.rglob(ext))

    # Filter files based on platform
    filtered_files = []
    for file_path in source_files:
        file_str = str(file_path)

        # Skip example directories
        if "examples" in file_str:
            continue

        # Skip platform-specific files for other platforms
        if platform == "macos":
            if (
                "/platform/linux/" in file_str
                or "/platform/windows/" in file_str
                or "/platform/android/" in file_str
                or "/platform/ios/" in file_str
                or "/platform/ohos/" in file_str
            ):
                continue
        elif platform == "ios":
            if (
                "/platform/linux/" in file_str
                or "/platform/windows/" in file_str
                or "/platform/android/" in file_str
                or "/platform/macos/" in file_str
                or "/platform/ohos/" in file_str
            ):
                continue

        filtered_files.append(file_path)

    return filtered_files


def update_nativeapi_mm(nativeapi_path, cxx_impl_dir, platform):
    """Update cnativeapi.mm file with include statements."""
    source_files = find_source_files(cxx_impl_dir, platform)
    print(f"Processing {len(source_files)} source files for {platform}...")

    # Read current file content
    with open(nativeapi_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Find the section with include statements
    # Look for the pattern that starts with "// Include source files"
    # This should match everything from "// Include source files" to the end of file
    include_pattern = r"(// Include source files\n)(.*?)(\Z)"

    match = re.search(include_pattern, content, re.DOTALL)

    if not match:
        print(
            f"Error: Could not find '// Include source files' marker in {nativeapi_path.name}"
        )
        return False

    # Generate new include statements
    new_includes = []

    # Categorize files for better organization
    capi_files = []
    platform_files = []
    core_files = []
    foundation_files = []

    for file_path in source_files:
        file_str = str(file_path)

        # Calculate relative path from cnativeapi.mm location
        # cnativeapi.mm is at packages/cnativeapi/{platform}/cnativeapi/Sources/cnativeapi/
        # cxx_impl is at packages/cnativeapi/cxx_impl/
        # So relative path should be ../../../../cxx_impl/src/...
        rel_path = os.path.relpath(file_path, nativeapi_path.parent)

        if "/capi/" in file_str:
            capi_files.append(rel_path)
        elif f"/platform/{platform}/" in file_str:
            platform_files.append(rel_path)
        elif "/foundation/" in file_str:
            foundation_files.append(rel_path)
        else:
            core_files.append(rel_path)

    # Add includes in organized order
    for file_path in (
        sorted(capi_files)
        + sorted(platform_files)
        + sorted(foundation_files)
        + sorted(core_files)
    ):
        new_includes.append(f'#include "{file_path}"')

    # Print summary of what was included
    print(f"  - C API files: {len(capi_files)}")
    print(f"  - Platform-specific files: {len(platform_files)}")
    print(f"  - Foundation files: {len(foundation_files)}")
    print(f"  - Core files: {len(core_files)}")

    # Build the new include section
    new_include_section = match.group(1) + "\n".join(new_includes)

    # Replace the old include section with the new one
    new_content = content[: match.start()] + new_include_section

    # Ensure file ends with a newline
    if not new_content.endswith("\n"):
        new_content += "\n"

    # Write back to file
    with open(nativeapi_path, "w", encoding="utf-8") as f:
        f.write(new_content)

    return True


def update_macos_mm(cnativeapi_dir, cxx_impl_dir):
    """Update macos/cnativeapi/Sources/cnativeapi/cnativeapi.mm."""
    print("\nStep 2/7: Updating macOS platform bindings")

    macos_mm_path = cnativeapi_dir / "macos/cnativeapi/Sources/cnativeapi/cnativeapi.mm"

    if not macos_mm_path.exists():
        print(f"Error: {macos_mm_path} not found")
        return False

    if update_nativeapi_mm(macos_mm_path, cxx_impl_dir, "macos"):
        print("macOS bindings updated successfully")
        return True
    else:
        print("Failed to update macOS bindings")
        return False


def update_ios_mm(cnativeapi_dir, cxx_impl_dir):
    """Update ios/cnativeapi/Sources/cnativeapi/cnativeapi.mm."""
    print("\nStep 3/7: Updating iOS platform bindings")

    ios_mm_path = cnativeapi_dir / "ios/cnativeapi/Sources/cnativeapi/cnativeapi.mm"

    if not ios_mm_path.exists():
        print(f"Error: {ios_mm_path} not found")
        return False

    if update_nativeapi_mm(ios_mm_path, cxx_impl_dir, "ios"):
        print("iOS bindings updated successfully")
        return True
    else:
        print("Failed to update iOS bindings")
        return False


def update_macos_h(cnativeapi_dir, cxx_impl_dir):
    """Update macos/cnativeapi/Sources/cnativeapi/include/cnativeapi.h."""
    print("\nStep 4/7: Updating macOS header file")

    macos_h_path = cnativeapi_dir / "macos/cnativeapi/Sources/cnativeapi/include/cnativeapi.h"

    if not macos_h_path.exists():
        print(f"Error: {macos_h_path} not found")
        return False

    if update_cnativeapi_h(macos_h_path, cxx_impl_dir):
        print("macOS header updated successfully")
        return True
    else:
        print("Failed to update macOS header")
        return False


def update_ios_h(cnativeapi_dir, cxx_impl_dir):
    """Update ios/cnativeapi/Sources/cnativeapi/include/cnativeapi.h."""
    print("\nStep 5/7: Updating iOS header file")

    ios_h_path = cnativeapi_dir / "ios/cnativeapi/Sources/cnativeapi/include/cnativeapi.h"

    if not ios_h_path.exists():
        print(f"Error: {ios_h_path} not found")
        return False

    if update_cnativeapi_h(ios_h_path, cxx_impl_dir):
        print("iOS header updated successfully")
        return True
    else:
        print("Failed to update iOS header")
        return False


def parse_args():
    parser = argparse.ArgumentParser(
        description="Regenerate cnativeapi bindings (optionally without updating submodules)."
    )
    parser.add_argument(
        "--no-submodule-update",
        action="store_true",
        help="Skip 'git submodule update --remote ...' (recommended for CI/codegen checks).",
    )
    return parser.parse_args()


def main():
    """Main function to regenerate bindings."""
    args = parse_args()
    cnativeapi_dir = Path(__file__).parent
    cxx_impl_dir = cnativeapi_dir / "cxx_impl"
    ffigen_path = cnativeapi_dir / "ffigen.yaml"

    print("\nNative API Bindings Generator")
    print("This script will regenerate all platform bindings\n")

    # Step 1: Update cxx_impl submodule
    if args.no_submodule_update:
        print("\nStep 1/7: Skipping cxx_impl submodule update (--no-submodule-update)")
    else:
        if not update_cxx_impl():
            print("\nWarning: cxx_impl update failed, continuing anyway...")

    # Verify cxx_impl exists
    if not cxx_impl_dir.exists():
        print(f"\nError: cxx_impl directory not found: {cxx_impl_dir}")
        return 1

    # Step 2: Update macos/cnativeapi/Sources/cnativeapi/cnativeapi.mm
    if not update_macos_mm(cnativeapi_dir, cxx_impl_dir):
        print("\nError: macOS bindings update failed")
        return 1

    # Step 3: Update ios/cnativeapi/Sources/cnativeapi/cnativeapi.mm
    if not update_ios_mm(cnativeapi_dir, cxx_impl_dir):
        print("\nError: iOS bindings update failed")
        return 1

    # Step 4: Update macos/cnativeapi/Sources/cnativeapi/include/cnativeapi.h
    if not update_macos_h(cnativeapi_dir, cxx_impl_dir):
        print("\nError: macOS header update failed")
        return 1

    # Step 5: Update ios/cnativeapi/Sources/cnativeapi/include/cnativeapi.h
    if not update_ios_h(cnativeapi_dir, cxx_impl_dir):
        print("\nError: iOS header update failed")
        return 1

    # Step 6: Update ffigen.yaml
    capi_headers = find_capi_headers(cxx_impl_dir)
    if not capi_headers:
        print("\nWarning: No C API headers found in cxx_impl")
    else:
        if not update_ffigen_yaml(ffigen_path, capi_headers):
            print("\nError: Failed to update ffigen configuration")
            return 1

    # Step 7: Generate bindings using ffigen
    print("\nStep 7/7: Generating Dart bindings")
    print("Running ffigen to generate Dart bindings from C headers...")

    ffigen_cmd = ["dart", "run", "ffigen", "--config", "ffigen.yaml"]
    if not run_command(ffigen_cmd, cwd=cnativeapi_dir):
        print("\nWarning: Failed to generate bindings with ffigen")
        print("You can manually run: dart run ffigen --config ffigen.yaml")
    else:
        print("Dart bindings generated successfully")

    print("\nAll steps completed successfully!")
    print("\nNext steps:")
    print("  1. Review the changes: git status")
    print("  2. Test the generated bindings")
    print("  3. Commit your changes if everything looks good\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
