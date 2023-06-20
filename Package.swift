// swift-tools-version:5.6
import PackageDescription
import Foundation

let package = Package(
    name: "muter",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "muter", targets: ["muter", "muterCore"]),
    ],
    dependencies: [
        .swiftSyntax,
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "4.0.1"),
        .package(url: "https://github.com/dduan/Pathos.git", from: "0.4.2"),
        .package(url: "https://github.com/jkandzi/Progress.swift.git", from: "0.4.0"),
        .package(url: "https://github.com/johnsundell/plot.git", from: "0.11.0"),
        .package(url: "https://github.com/krzysztofzablocki/Difference.git", from: "1.0.2"),
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
                "Difference",
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

func xcodeVersion() -> String {
    Executable("/usr/bin/xcrun")("xcodebuild", "-version")?
        .components(separatedBy: "\n")
        .first ?? ""
}

extension Version {
    static var swiftSyntaxTag: Self? {
        let xcode = xcodeVersion()
        
        if xcode.contains("Xcode 11.4") {
            return "0.50200.0"
        }
        if xcode.contains("Xcode 12.0") {
            return "0.50300.0"
        }
        if xcode.contains("Xcode 12.5") {
            return "0.50400.0"
        }
        if xcode.contains("Xcode 13.0") {
            return "0.50500.0"
        }
        if xcode.contains("Xcode 13.3") {
            return "0.50600.1"
        }
        if xcode.contains("Xcode 14.0") {
            return "0.50700.1"
        }
        if xcode.contains("Xcode 14.3") {
            return "508.0.0"
        }
        
        return nil
    }
}

extension Package.Dependency {
    static var swiftSyntax: Package.Dependency {
        if let version = Version.swiftSyntaxTag {
            return .package(url: "https://github.com/apple/swift-syntax.git", from: version)
        }
        
        return .package(url: "https://github.com/apple/swift-syntax.git", branch: "main")
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
}

private struct Executable {
    private let url: URL

    init(_ filePath: String) {
        url = URL(fileURLWithPath: filePath)
    }

    func callAsFunction(_ arguments: String...) -> String? {
        let process = Process()
        process.executableURL = url
        process.arguments = arguments

        let stdout = Pipe()
        process.standardOutput = stdout

        process.launch()
        process.waitUntilExit()

        return stdout.readStringToEndOfFile()
    }
}

extension Pipe {
    func readStringToEndOfFile() -> String? {
        let data: Data
        if #available(OSX 10.15.4, *) {
            data = (try? fileHandleForReading.readToEnd()) ?? Data()
        } else {
            data = fileHandleForReading.readDataToEndOfFile()
        }

        return String(data: data, encoding: .utf8)
    }
}
