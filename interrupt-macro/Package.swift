// swift-tools-version: 6.4

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "interrupt-macro",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "InterruptMacroPlugin", targets: ["InterruptMacroPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "603.0.0"),
    ],
    targets: [
        .macro(
            name: "InterruptMacroPluginImpl",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "InterruptMacroPlugin",
            dependencies: ["InterruptMacroPluginImpl"]
        ),
    ]
)
