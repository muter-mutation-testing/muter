// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "muter",
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", .branch("0.40200.0")),
		.package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0")
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
            name: "testingCore",
			dependencies: ["muterCore"]
        ),
        .testTarget(
            name: "muterTests",
            dependencies: ["muterCore", "testingCore"],
            exclude: ["fixtures", "acceptanceTests"]
        ),
        .testTarget(
            name: "acceptanceTests",
            dependencies: ["muterCore", "testingCore"]
        )
    ]
)
