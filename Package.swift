// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "muter",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .executable(name: "muter", targets: ["muter", "muterCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", .revision("swift-5.3-DEVELOPMENT-SNAPSHOT-2020-09-07-a")),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
        .package(url: "https://github.com/Quick/Quick", from: "1.3.2"),
        .package(url: "https://github.com/Quick/Nimble", from: "7.3.1"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.3.0"),
        .package(url: "https://github.com/thoughtbot/Curry.git", from: "4.0.2"),
        .package(url: "https://github.com/jkandzi/Progress.swift", from: "0.4.0"),
        .package(url: "https://github.com/dduan/Pathos", from: "0.2.0")
        
    ],
    targets: [
        .target(
            name: "muter",
            dependencies: ["muterCore", "ArgumentParser"]
        ),
        .target(
            name: "muterCore",
            dependencies: ["SwiftSyntax", "Rainbow", "ArgumentParser", "Curry", "Progress", "Pathos"],
            path: "Sources/muterCore"
        ),        
        .target(
            name: "TestingExtensions",
            dependencies: ["SwiftSyntax", "muterCore", "Quick", "Nimble"],
            path: "Tests/Extensions"
        ),
        .testTarget(
            name: "muterTests",
            dependencies: ["muterCore", "TestingExtensions"],
            path: "Tests",
            exclude: ["fixtures", "Extensions"]
        ),
        .testTarget(
            name: "muterAcceptanceTests",
            dependencies: ["muterCore", "TestingExtensions"],
            path: "AcceptanceTests"
        ),
        .testTarget(
            name: "muterRegressionTests",
            dependencies: ["muterCore", "TestingExtensions", "SnapshotTesting"],
            path: "RegressionTests"
        )
    ]
)
