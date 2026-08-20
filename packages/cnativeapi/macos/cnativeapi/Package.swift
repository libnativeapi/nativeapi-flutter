// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cnativeapi",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "cnativeapi",
            type: .dynamic,
            targets: ["cnativeapi"]
        )
    ],
    dependencies: [
        // No external dependencies for now
    ],
    targets: [
        .target(
            name: "cnativeapi",
            dependencies: [],
            path: "Sources/cnativeapi",
            sources: [
                "cnativeapi.mm",
                // The C API translation units (src/capi/*.cpp) need not be
                // listed here: cnativeapi.mm #includes them into a single unity
                // translation unit, and their conversion helpers are defined in
                // the *_c.h that owns each type, so no redefinition errors occur.
            ],
            publicHeadersPath: "include",
            cxxSettings: [
                .define("OBJC_OLD_DISPATCH_PROTOTYPES", to: "0"),
                .unsafeFlags([
                    "-std=c++17",
                    "-x", "objective-c++",
                ]),
            ],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("Cocoa"),
                .linkedFramework("Foundation"),
                .linkedFramework("ServiceManagement"),
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)
