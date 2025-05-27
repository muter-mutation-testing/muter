// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProjectWithTimeout",
    products: [
        .library(
            name: "ProjectWithTimeout",
            targets: ["ProjectWithTimeout"]),
    ],
    targets: [
        .target(
            name: "ProjectWithTimeout"),
        .testTarget(
            name: "ProjectWithTimeoutTests",
            dependencies: ["ProjectWithTimeout"]
        ),
    ]
)
