// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "muter",
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", 
        .branch("swift-DEVELOPMENT-SNAPSHOT-2018-08-25-a")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "muter",
            dependencies: ["SwiftSyntax"]),
        .testTarget(
            name: "muterTests",
            dependencies: ["muter"]),
    ]
)
