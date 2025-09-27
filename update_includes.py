#!/usr/bin/env python3
"""
Script to update include statements in nativeapi.mm based on available source files.
This script automatically scans for C++ and Objective-C++ source files and updates
the include statements in the nativeapi.mm file.
"""

import os
import re
from pathlib import Path

def find_source_files(src_dir):
    """Find all .cpp and .mm source files in the specified directory."""
    source_files = []

    # Find all C++ and Objective-C++ files
    for ext in ['*.cpp', '*.mm']:
        source_files.extend(Path(src_dir).rglob(ext))

    # Filter files for macOS build
    filtered_files = []
    for file_path in source_files:
        file_str = str(file_path)

        # Skip example directories
        if 'examples' in file_str:
            continue

        # Skip platform-specific files for other platforms
        if '/platform/linux/' in file_str or '/platform/windows/' in file_str:
            continue

        # Convert to relative path from nativeapi.mm location
        rel_path = os.path.relpath(file_path, Path(__file__).parent / 'packages/cnativeapi/macos/Classes')
        filtered_files.append(rel_path)

    return sorted(filtered_files)

def update_nativeapi_mm(nativeapi_path, source_files):
    """Update the nativeapi.mm file with new include statements."""

    # Read current file content
    with open(nativeapi_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the section with include statements
    # Look for the pattern that starts with "// Include source files"
    include_pattern = r'(// Include source files\n)(.*?)(\n\n|\Z)'

    match = re.search(include_pattern, content, re.DOTALL)

    if not match:
        print("Could not find '// Include source files' section in nativeapi.mm")
        return False

    # Generate new include statements
    new_includes = []

    # Categorize files for better organization
    capi_files = []
    platform_files = []
    core_files = []

    for file_path in source_files:
        if '/capi/' in file_path:
            capi_files.append(file_path)
        elif '/platform/macos/' in file_path:
            platform_files.append(file_path)
        else:
            core_files.append(file_path)

    # Add includes in organized order
    for file_path in capi_files + platform_files + core_files:
        new_includes.append(f'#include "{file_path}"')

    # Build the new include section
    new_include_section = match.group(1) + '\n'.join(new_includes)

    # Replace the old include section with the new one
    new_content = content[:match.start()] + new_include_section + content[match.end()-1:]

    # Write back to file
    with open(nativeapi_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    return True

def main():
    """Main function to update include statements."""
    script_dir = Path(__file__).parent

    # Define paths
    src_dir = script_dir / 'packages/cnativeapi/src'
    nativeapi_path = script_dir / 'packages/cnativeapi/macos/Classes/nativeapi.mm'

    if not src_dir.exists():
        print(f"Source directory not found: {src_dir}")
        return 1

    if not nativeapi_path.exists():
        print(f"nativeapi.mm file not found: {nativeapi_path}")
        return 1

    # Find all source files
    print("Scanning for source files...")
    source_files = find_source_files(src_dir)

    print(f"Found {len(source_files)} source files:")
    for file_path in source_files:
        print(f"  {file_path}")

    # Update nativeapi.mm
    print(f"\nUpdating {nativeapi_path}...")
    if update_nativeapi_mm(nativeapi_path, source_files):
        print("Successfully updated nativeapi.mm!")
        return 0
    else:
        print("Failed to update nativeapi.mm")
        return 1

if __name__ == '__main__':
    exit(main())
