// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "muter",
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", .branch("swift-DEVELOPMENT-SNAPSHOT-2018-08-25-a")),
    ],
    targets: [
        .target(
            name: "muter",
            dependencies: ["SwiftSyntax"]),
        .testTarget(
            name: "muterTests",
            dependencies: ["muter"]),
    ]
)
