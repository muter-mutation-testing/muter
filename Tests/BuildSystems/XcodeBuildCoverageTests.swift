@testable import muterCore
import TestingExtensions
import XCTest

final class XcodeBuildCoverageTests: MuterTestCase {
    private let sut = XcodeBuildCoverage()

    private var coverageThreshold: Double = 0
    private lazy var muterConfiguration = MuterConfiguration(
        executable: "/path/to/xcodebuild",
        arguments: [],
        coverageThreshold: coverageThreshold
    )

    func test_whenUsesSupportedBuildSystem_shouldRunWithCoverage() {
        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(process.executableURL?.path, "/path/to/xcodebuild")
        XCTAssertEqual(process.arguments, ["-derivedDataPath", "DerivedData", "-enableCodeCoverage", "YES"])
    }

    func test_whenTheUserSetsADerivedDataPath_thenTheCoverageRunUsesIt() {
        let configuration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["-scheme", "App", "-derivedDataPath", "/custom/DerivedData", "test"]
        )

        _ = sut.run(with: configuration)

        XCTAssertEqual(
            process.arguments,
            ["-scheme", "App", "-derivedDataPath", "/custom/DerivedData", "test", "-enableCodeCoverage", "YES"]
        )
        XCTAssertEqual(sut.buildDirectory(configuration), "/custom/DerivedData")
    }

    func test_buildDirectory_isTheDerivedDataPath_withoutShowBuildSettings() {
        // Xcode prints no build settings for a Swift package, so Muter no longer runs -showBuildSettings.
        let buildDirectory = sut.buildDirectory(muterConfiguration)

        XCTAssertEqual(buildDirectory?.hasSuffix("/DerivedData"), true, buildDirectory ?? "nil")
        XCTAssertEqual(buildDirectory?.hasPrefix("/"), true, buildDirectory ?? "nil")
        XCTAssertNil(process.arguments)
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
