// swift-tools-version:5.6
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
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "4.0.1"),
        .package(url: "https://github.com/dduan/Pathos.git", from: "0.4.2"),
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "0.50700.1"),
        .package(url: "https://github.com/jkandzi/Progress.swift.git", from: "0.4.0"),
        .package(url: "https://github.com/johnsundell/plot.git", from: "0.11.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.1"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.9.0")
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
            ],
            path: "Sources/muterCore"
        ),
        .target(
            name: "TestingExtensions",
            dependencies: [
                "muterCore",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
            ],
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
            path: "AcceptanceTests",
            exclude: ["runAcceptanceTests.sh"]
        ),
        .testTarget(
            name: "muterRegressionTests",
            dependencies: [
                "muterCore",
                "TestingExtensions",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "RegressionTests",
            exclude: ["__Snapshots__", "runRegressionTests.sh"]
        )
    ]
)
