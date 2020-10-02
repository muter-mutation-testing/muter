// swift-tools-version:5.3
import PackageDescription
import Foundation

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

let rPathLinkerSetting: LinkerSetting = {
    let xcodeSelectPath = Executable("/usr/bin/xcode-select")("-p") ?? ""
    let searchPath = xcodeSelectPath.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        + "/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx"
    
    return .unsafeFlags([
        "-rpath",
        searchPath
    ])
}()

let package = Package(
    name: "muter",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "muter", targets: ["muter", "muterCore"]),
    ],
    dependencies: [
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .revision("0.50300.0")),
        .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.1.0"),
        .package(name: "Progress", url: "https://github.com/jkandzi/Progress.swift", from: "0.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.3.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
        .package(url: "https://github.com/Quick/Quick", from: "1.3.2"),
        .package(url: "https://github.com/Quick/Nimble", from: "7.3.1"),
        .package(url: "https://github.com/thoughtbot/Curry.git", from: "4.0.2"),
        .package(url: "https://github.com/dduan/Pathos", from: "0.2.0"),
        .package(name: "Difference", url: "https://github.com/krzysztofzablocki/Difference.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "muter",
            dependencies: [
                "muterCore", 
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "muterCore",
            dependencies: [
                "SwiftSyntax", 
                "Rainbow", 
                "Curry",
                "Progress",
                "Pathos",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/muterCore"
        ),        
        .target(
            name: "TestingExtensions",
            dependencies: ["SwiftSyntax", "muterCore", "Difference", "Quick", "Nimble"],
            path: "Tests/Extensions",
            linkerSettings: [rPathLinkerSetting]
        ),
        .testTarget(
            name: "muterTests",
            dependencies: ["muterCore", "TestingExtensions"],
            path: "Tests",
            exclude: ["fixtures", "Extensions"],
            linkerSettings: [rPathLinkerSetting]
        ),
        .testTarget(
            name: "muterAcceptanceTests",
            dependencies: ["muterCore", "TestingExtensions"],
            path: "AcceptanceTests",
            exclude: ["samples", "runAcceptanceTests.sh"],
            linkerSettings: [rPathLinkerSetting]
        ),
        .testTarget(
            name: "muterRegressionTests",
            dependencies: ["muterCore", "TestingExtensions", "SnapshotTesting"],
            path: "RegressionTests",
            exclude: ["samples", "__Snapshots__", "runRegressionTests.sh"],
            linkerSettings: [rPathLinkerSetting]
        )
    ]
)
