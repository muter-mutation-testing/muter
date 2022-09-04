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
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.4"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "4.0.1"),
        .package(url: "https://github.com/Quick/Quick.git", from: "5.0.1"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "10.0.0"),
        .package(url: "https://github.com/dduan/Pathos.git", from: "0.4.2"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "0.50600.1"),
        .package(url: "https://github.com/jkandzi/Progress.swift.git", from: "0.4.0"),
        .package(url: "https://github.com/johnsundell/plot.git", from: "0.11.0"),
        .package(url: "https://github.com/krzysztofzablocki/Difference.git", from: "1.0.1"),
    ],
    targets: [
        .executableTarget(
            name: "muter",
            dependencies: ["muterCore"]
        ),
        .target(
            name: "muterCore",
            dependencies: [
                "Rainbow",
                "Pathos",
                .product(name: "Plot", package: "plot"),
                .product(name: "Progress", package: "Progress.swift"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/muterCore"
        ),
        .target(
            name: "TestingExtensions",
            dependencies: [
                "muterCore",
                "Difference",
                "Quick",
                "Nimble",
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
    ]
)

resolveTestTargetFromEnvironmentVarialbes()
hookInternalSwiftSyntaxParser()
isDebuggingMain(false)

/// Make sure to select a single test target
/// This is important because, as of today, we cannot pick a single test target from the command-line (and filtering also doesn't help)
/// With that in mind, this (a hack, for sure) will look-up for an env var and pick the test target accodingly.
func resolveTestTargetFromEnvironmentVarialbes() {
    let shouldAddAcceptanceTests = ProcessInfo.processInfo.environment.keys.contains("acceptance_tests")
    let shouldAddRegressionTests = ProcessInfo.processInfo.environment.keys.contains("regression_tests")

    if shouldAddAcceptanceTests || shouldAddRegressionTests {
        package.targets.removeAll(where: \.isTest)
    }

    if shouldAddAcceptanceTests {
        package.targets.append(
            .testTarget(
                name: "muterAcceptanceTests",
                dependencies: ["muterCore", "TestingExtensions"],
                path: "AcceptanceTests",
                exclude: ["samples", "runAcceptanceTests.sh"]
            )
        )
    }

    if shouldAddRegressionTests {
        package.dependencies.append(
            .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.9.0")
        )

        package.targets.append(
            .testTarget(
                name: "muterRegressionTests",
                dependencies: [
                    "muterCore",
                    "TestingExtensions",
                    .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                ],
                path: "RegressionTests",
                exclude: ["samples", "__Snapshots__", "runRegressionTests.sh"]
            )
        )
    }
}

/// We need to manually add an -rpath to the project so the tests can run via Xcode
/// If we are running from console (swift build & friend) we don't need to do it
func hookInternalSwiftSyntaxParser() {
    let isFromTerminal = ProcessInfo.processInfo.environment.values.contains("/usr/bin/swift")
    if !isFromTerminal {
        package
            .targets
            .filter(\.isTest)
            .forEach { $0.installSwiftSyntaxParser() }
    }
}

/// When debuging from Xcode (via command + R) we need to do the dylib dance
func isDebuggingMain(_ isDebug: Bool) {
    if isDebug {
        package
            .targets
            .filter { $0.name == "muter" }
            .first?
            .installSwiftSyntaxParser()
    }
}

extension PackageDescription.Target {
    func installSwiftSyntaxParser() {
        linkerSettings = [linkerSetting]
    }

    private var linkerSetting: LinkerSetting {
        guard let xcodeFolder = Executable("/usr/bin/xcode-select")("-p") else {
            fatalError("Could not run `xcode-select -p`")
        }

        let toolchainFolder = "\(xcodeFolder.trimmed)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx"

        return .unsafeFlags(["-rpath", toolchainFolder])
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
