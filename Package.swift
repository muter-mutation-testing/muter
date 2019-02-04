// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "muter",
    products: [
        .executable(name: "muter", targets: ["muter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", .branch("0.40200.0")),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
        .package(url: "https://github.com/Quick/Quick", from: "1.3.2"),
        .package(url: "https://github.com/Quick/Nimble", from: "7.3.1")
    ],
    targets: [
        .target(
            name: "muter",
            dependencies: ["muterCore"]
        ),
        .target(
            name: "muterCore",
            dependencies: ["SwiftSyntax", "Rainbow"],
            path: "Sources/muterCore"
        ),
        .testTarget(
            name: "muterTests",
            dependencies: ["muterCore", "Quick", "Nimble"],
            path: "Tests",
            exclude: ["fixtures"]
        )
    ]
)
