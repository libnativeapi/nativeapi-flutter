// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cnativeapi",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "cnativeapi",
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
                "cnativeapi.mm"
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
                .linkedFramework("UIKit"),
                .linkedFramework("Foundation"),
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)

