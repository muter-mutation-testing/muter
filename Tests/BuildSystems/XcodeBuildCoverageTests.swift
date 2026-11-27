@testable import muterCore
import TestingExtensions
import XCTest

final class XcodeBuildCoverageTests: MuterTestCase {
    private let sut = XcodeBuildCoverage()

    private var coverageThreshold: Double = 0
    private lazy var muterConfiguration = MuterConfiguration(
        executable: "/path/to/xcodebuild",
        arguments: ["-project", "App.xcodeproj"],
        coverageThreshold: coverageThreshold
    )

    private let packageConfiguration = MuterConfiguration(
        executable: "/path/to/xcodebuild",
        arguments: ["-scheme", "IOSCore", "test"]
    )

    func test_whenUsesSupportedBuildSystem_shouldRunWithCoverage() {
        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(process.executableURL?.path, "/path/to/xcodebuild")
        // A project keeps its own build location: no -derivedDataPath is added.
        XCTAssertEqual(process.arguments, ["-project", "App.xcodeproj", "-enableCodeCoverage", "YES", "COMPILER_INDEX_STORE_ENABLE=YES"])
    }

    func test_project_buildDirectoryComesFromShowBuildSettings() {
        process.stdoutToBeReturned = "    BUILD_DIR = /custom/build/Products\n"

        XCTAssertEqual(sut.buildDirectory(muterConfiguration), "/custom/build")
        XCTAssertEqual(process.arguments, ["-project", "App.xcodeproj", "-showBuildSettings"])
    }

    func test_indexStore_isInTheDerivedDataFolder() {
        // A project: the build directory is `<DerivedData>/<Project-hash>/Build`.
        XCTAssertEqual(
            sut.indexStorePath(muterConfiguration, buildDirectory: "/DerivedData/App-hash/Build"),
            "/DerivedData/App-hash/Index.noindex/DataStore"
        )
        // A Swift package: the build directory is the derived data folder.
        XCTAssertEqual(
            sut.indexStorePath(packageConfiguration, buildDirectory: "/custom/DerivedData"),
            "/custom/DerivedData/Index.noindex/DataStore"
        )
    }

    func test_whenTheTestCommandSetsTheIndexStore_thenMuterKeepsIt() {
        let configuration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["-project", "App.xcodeproj", "COMPILER_INDEX_STORE_ENABLE=NO"]
        )

        XCTAssertEqual(
            configuration.enableCoverageArguments,
            ["-project", "App.xcodeproj", "COMPILER_INDEX_STORE_ENABLE=NO", "-enableCodeCoverage", "YES"]
        )
    }

    func test_buildDir_isOnlyTheValue() {
        let output = """
        Build settings for action test and target App:
            BUILD_DIR = /custom/build/Products
            BUILD_ROOT = /custom/build/Products
        """

        XCTAssertEqual(XcodeBuildCoverage.buildDir(inBuildSettings: output), "/custom/build/Products")
        XCTAssertNil(XcodeBuildCoverage.buildDir(inBuildSettings: "Resolved source packages:"))
    }

    func test_swiftPackage_coverageRunUsesADerivedDataPath() {
        _ = sut.run(with: packageConfiguration)

        XCTAssertEqual(
            process.arguments,
            ["-scheme", "IOSCore", "test", "-derivedDataPath", "DerivedData", "-enableCodeCoverage", "YES", "COMPILER_INDEX_STORE_ENABLE=YES"]
        )
    }

    func test_swiftPackage_buildDirectoryIsTheDerivedDataPath_withoutShowBuildSettings() {
        // Xcode prints no build settings for a Swift package.
        let buildDirectory = sut.buildDirectory(packageConfiguration)

        XCTAssertEqual(buildDirectory?.hasSuffix("/DerivedData"), true, buildDirectory ?? "nil")
        XCTAssertEqual(buildDirectory?.hasPrefix("/"), true, buildDirectory ?? "nil")
        XCTAssertNil(process.arguments)
    }

    func test_swiftPackage_whenTheUserSetsADerivedDataPath_thenItIsUsed() {
        let configuration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["-scheme", "IOSCore", "-derivedDataPath", "/custom/DerivedData", "test"]
        )

        _ = sut.run(with: configuration)

        XCTAssertEqual(
            process.arguments,
            ["-scheme", "IOSCore", "-derivedDataPath", "/custom/DerivedData", "test", "-enableCodeCoverage", "YES", "COMPILER_INDEX_STORE_ENABLE=YES"]
        )
        XCTAssertEqual(sut.buildDirectory(configuration), "/custom/DerivedData")
    }

    func test_whenRunWithCoverageSucceeds_thenRunXcovCommand() {
        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
        process.stdoutToBeReturned = "/path/to/xcrun"

        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(process.executableURL?.path, "/path/to/xcrun")
        XCTAssertEqual(
            process.arguments,
            ["xccov", "view", "--report", "--json", "path/to/testResult.xcresult"]
        )
    }

    func test_whenXcovSucceeds_thenReturnFilsWithoutCoverage() throws {
        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
        process.stdoutToBeReturned = "/path/to/xcrun"
        process.stdoutToBeReturned = coverageData

        let coverage = try XCTUnwrap(sut.run(with: muterConfiguration).get())

        XCTAssertEqual(
            coverage,
            .make(
                percent: 81,
                filesWithoutCoverage: ["/path/to/file1.swift"]
            )
        )
    }

    func test_ignoreFilesLessThanCoverageThreshold() throws {
        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
        process.stdoutToBeReturned = "/path/to/xcrun"
        process.stdoutToBeReturned = coverageData

        coverageThreshold = 10

        let coverage = try XCTUnwrap(sut.run(with: muterConfiguration).get())

        XCTAssertEqual(
            coverage,
            .make(
                percent: 81,
                filesWithoutCoverage: [
                    "/path/to/file1.swift",
                    "/path/to/file2.swift",
                    "/path/to/file3.swift",
                ]
            )
        )
    }

    func test_whenXcodeSelectFails_shouldNotRunXccov() {
        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
        process.stdoutToBeReturned = "/path/to/xcrun"
        process.stdoutToBeReturned = ""

        _ = sut.run(with: muterConfiguration)

        XCTAssertFalse(
            process.executableURL?.path.contains("xccov")
        )
    }

    func test_whenBuildFailes_shouldNotExecuteXcodeSelect() {
        process.stdoutToBeReturned = ""

        _ = sut.run(with: muterConfiguration)

        XCTAssertNotEqual(process.executableURL?.path, "/usr/bin/xcode-select")
    }

    func test_functionCoverage() throws {
        process.stdoutToBeReturned = "BUILD_DIR = /build/directory"
        process.stdoutToBeReturned = "/path/to/testExecutable.xctest"
        process.stdoutToBeReturned = "/path/to/testBinary"
        process.stdoutToBeReturned = "/path/to/coverage.profdata"
        process.stdoutToBeReturned = "/path/to/xcrun"
        process.stdoutToBeReturned = loadFixture("llvmCovExport.json")

        let functionsCoverage = sut.functionsCoverage(muterConfiguration)

        XCTAssertEqual(
            functionsCoverage.regionsForFile("/path/to/file.swift"), [
                .make(
                    lineStart: 14,
                    columnStart: 80,
                    lineEnd: 24,
                    columnEnd: 4,
                    executionCount: 0
                ),
            ]
        )
    }
}

let coverageData =
    """
    {
      "targets": [
        {
          "lineCoverage": 0.81051478641840091,
          "files": [
            {
              "lineCoverage": 0,
              "path": "/path/to/file1.swift"
            },
            {
              "lineCoverage": 0.10,
              "path": "/path/to/file2.swift"
            },
            {
              "lineCoverage": 0.20,
              "path": "/path/to/file3.swift"
            }
          ],
         "name": "Project.framework"
        },
        {
          "lineCoverage": 0.86051478641840091,
          "files": [
            {
              "lineCoverage": 0,
              "path": "/path/to/file4.swift"
            },
            {
              "lineCoverage": 0.10,
              "path": "/path/to/file5.swift"
            },
            {
              "lineCoverage": 0.20,
              "path": "/path/to/file6.swift"
            }
          ],
         "name": "Project-OSXTests.xctest"
        }
      ]
    }
    """
