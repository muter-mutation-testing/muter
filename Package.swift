// swift-tools-version:5.8

import Foundation
import PackageDescription

let package = Package(
    name: "muter",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "muter", targets: ["muter", "muterCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "4.0.1"),
        .package(url: "https://github.com/dduan/Pathos.git", from: "0.4.2"),
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "508.0.0"),
        .package(url: "https://github.com/jkandzi/Progress.swift.git", from: "0.4.0"),
        .package(url: "https://github.com/johnsundell/plot.git", from: "0.14.0"),
        .package(url: "https://github.com/krzysztofzablocki/Difference.git", from: "1.0.2"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.11.1"),
        .package(url: "https://github.com/mxcl/Version.git", from: "2.0.1")
    ],
    targets: [
        .executableTarget(
            name: "muter",
            dependencies: ["muterCore"]
        ),
        .target(
            name: "muterCore",
            dependencies: [
                .product(name: "Pathos", package: "Pathos"),
                .product(name: "Rainbow", package: "Rainbow"),
                .product(name: "Plot", package: "plot"),
                .product(name: "Progress", package: "Progress.swift"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "yams"),
                .product(name: "Version", package: "Version")
            ],
            path: "Sources/muterCore"
        ),
        .target(
            name: "TestingExtensions",
            dependencies: [
                "muterCore",
                "Difference",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "Tests/Extensions"
        ),
        .testTarget(
            name: "muterTests",
            dependencies: [
                "muterCore",
                "TestingExtensions"
            ],
            path: "Tests",
            exclude: [
                "MutationSchemata/__Snapshots__",
                "TestReporting/__Snapshots__",
                "fixtures",
                "Extensions"
            ]
        ),
        .testTarget(
            name: "muterAcceptanceTests",
            dependencies: [
                "muterCore",
                "TestingExtensions",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "AcceptanceTests",
            exclude: [
                "__Snapshots__",
                "runAcceptanceTests.sh"
            ]
        ),
        .testTarget(
            name: "muterRegressionTests",
            dependencies: [
                "muterCore",
                "TestingExtensions",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "RegressionTests",
            exclude: [
                "__Snapshots__",
                "runRegressionTests.sh"
            ]
        )
    ]
)
