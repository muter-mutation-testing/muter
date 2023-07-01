@testable import muterCore
import TestingExtensions
import XCTest

final class XcodeCoverageTests: MuterTestCase {
    private let sut = XcodeCoverage()

    private let muterConfiguration = MuterConfiguration(
        executable: "/path/to/xcodebuild",
        arguments: []
    )

    func test_whenUsesSupportedBuildSystem_shouldRunWithCoverage() {
        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(process.executableURL?.path, "/path/to/xcodebuild")
        XCTAssertEqual(process.arguments, ["-enableCodeCoverage", "YES"])
    }

    func test_whenRunWithCoverageSucceeds_thenRunXcovCommand() {
        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"

        _ = sut.run(with: muterConfiguration)

        XCTAssertEqual(process.executableURL?.path, "/usr/bin/xcrun")
        XCTAssertEqual(
            process.arguments,
            ["xccov", "view", "--report", "--json", "path/to/testResult.xcresult"]
        )
    }

    func test_whenXcovSucceeds_thenReturnFilsWithoutCoverage() throws {
        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
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

    func test_whenXcodeSelectFails_shouldNotRunXccov() {
        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
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
}

let coverageData =
    """
    {
      "targets": [
        {
          "lineCoverage": 0.81051478641840091,
          "files": [
            {
              "coveredLines": 0,
              "path": "/path/to/file1.swift"
            },
            {
              "coveredLines": 10,
              "path": "/path/to/file2.swift"
            },
            {
              "coveredLines": 20,
              "path": "/path/to/file3.swift"
            }
          ],
         "name": "Project.framework"
        },
        {
          "lineCoverage": 0.86051478641840091,
          "files": [
            {
              "coveredLines": 0,
              "path": "/path/to/file4.swift"
            },
            {
              "coveredLines": 10,
              "path": "/path/to/file5.swift"
            },
            {
              "coveredLines": 20,
              "path": "/path/to/file6.swift"
            }
          ],
         "name": "Project-OSXTests.xctest"
        }
      ]
    }
    """
