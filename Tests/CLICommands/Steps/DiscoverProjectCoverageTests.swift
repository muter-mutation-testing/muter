import XCTest

@testable import muterCore

final class DiscoverProjectCoverageTests: XCTestCase {
    private let notificationCenter = NotificationCenter()
    private let state = RunCommandState()
    private let process = LaunchableSpy()
    
    private lazy var sut = DiscoverProjectCoverage(
        process: self.process,
        notificationCenter: notificationCenter
    )
    
    func test_whenStepStarts_shouldFireNotification() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["arg0", "arg1"]
        )
        
        let expectation = expectation(
            forNotification: .projectCoverageDiscoveryStarted,
            object: nil,
            notificationCenter: notificationCenter
        )
        
        _ = sut.run(with: state)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func test_whenUsesSupportedBuildSystem_shouldRunWithCoverage() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["arg0", "arg1"]
        )
        
        _ = sut.run(with: state)
        
        XCTAssertEqual(process.executableURL?.absoluteString, "file:///path/to/xcodebuild")
        XCTAssertEqual(process.arguments, ["arg0", "arg1", "-enableCodeCoverage", "YES"])
        XCTAssertTrue(process.runCalled)
        XCTAssertTrue(process.waitUntilExitCalled)
    }
    
    func test_whenBuildSucceeds_shouldRunXcodeSelectCommand() {
        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
        
        _ = sut.run(with: state)
        
        XCTAssertEqual(process.executableURL?.absoluteString, "file:///usr/bin/xcode-select")
        XCTAssertEqual(process.arguments, ["-p"])
    }
    
    func test_whenXcodeSelectSucceeds_thenRunXccovCommand() {
        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
        process.stdoutToBeReturned = "/path/to/xccov"
        
        _ = sut.run(with: state)
        
        XCTAssertEqual(process.executableURL?.absoluteString, "file:///path/to/xccov/usr/bin/xccov")
        XCTAssertEqual(process.arguments, ["view", "--report", "--json", "path/to/testResult.xcresult"])
    }
    
    func test_whenXccovSucceeds_thenReturnFilsWithoutCoverage() throws {
        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
        process.stdoutToBeReturned = "/path/to/xccov"
        process.stdoutToBeReturned = coverageData
        
        let result = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(
            result, [
                .projectCoverage(
                    Coverage.make(
                        percent: 81,
                        filesWithoutCoverage: ["/path/to/file1.swift"]
                    )
                )
            ]
        )
    }
    
    func test_whenXcodeSelectFailes_shouldNotRunXccov() {
        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
        process.stdoutToBeReturned = ""
        
        _ = sut.run(with: state)
        
        XCTAssertEqual(
            process.executableURL?.absoluteString.contains("xccov"),
            false
        )
    }
    
    func test_whenBuildFailes_shouldNotExecuteXcodeSelect() {
        process.stdoutToBeReturned = ""
        
        _ = sut.run(with: state)
        
        XCTAssertNotEqual(process.executableURL?.absoluteString, "file:///usr/bin/xcode-select")
    }
    
    func test_whenProjectUsesSwiftBuildSystem_thenRunCoverageCommand() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/swift",
            arguments: ["arg0", "arg1"]
        )
        
        _ = sut.run(with: state)
        
        XCTAssertEqual(process.executableURL?.absoluteString, "file:///path/to/swift")
        XCTAssertEqual(process.arguments, ["arg0", "arg1", "--enable-code-coverage", "--verbose"])
        XCTAssertTrue(process.runCalled)
        XCTAssertTrue(process.waitUntilExitCalled)
    }
    
    func test_whenBuildSucceeds_thenRunLlvmCovCommand() {
        process.stdoutToBeReturned =
                                        """
                                        Test Suite 'muterPackageTests.xctest' failed at 2021-02-25 16:20:37.112.
                                             Executed 144 tests, with 5 failures (0 unexpected) in 2.109 (2.116) seconds
                                        Test Suite 'All tests' failed at 2021-02-25 16:20:37.113.
                                             Executed 144 tests, with 5 failures (0 unexpected) in 2.109 (2.117) seconds
                                        /path/to/llvm-profdata merge -sparse /path/to/default16636031009452225957_0.profraw -o /path/to/default.profdata
                                        /path/to/llvm-cov export -instr-profile=/path/to/default.profdata /path/to/muterPackageTests
                                        """
        
        _ = sut.run(with: state)
        
        XCTAssertEqual(process.executableURL?.absoluteString, "file:///path/to/llvm-cov")
        XCTAssertEqual(
            process.arguments, [
                "report",
                "-instr-profile=/path/to/default.profdata",
                "/path/to/muterPackageTests",
                "--ignore-filename-regex=.build|Tests",
            ]
        )
    }
    
    func test_whenLlvmCovSucceeds_thenParseResults() throws {
        process.stdoutToBeReturned =
            """
            Test Suite 'muterPackageTests.xctest' failed at 2021-02-25 16:20:37.112.
                 Executed 144 tests, with 5 failures (0 unexpected) in 2.109 (2.116) seconds
            Test Suite 'All tests' failed at 2021-02-25 16:20:37.113.
                 Executed 144 tests, with 5 failures (0 unexpected) in 2.109 (2.117) seconds
            /path/to/llvm-profdata merge -sparse /path/to/default16636031009452225957_0.profraw -o /path/to/default.profdata
            /path/to/llvm-cov export -instr-profile=/path/to/default.profdata /path/to/muterPackageTests
            """

        process.stdoutToBeReturned = loadLLVMCovLog()
        
        let result = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(
            result, [
                .projectCoverage(
                    Coverage.make(
                        percent: 78,
                        filesWithoutCoverage: [
                            "CLICommands/MuterError.swift",
                            "Extensions/Nullable.swift",
                            "Extensions/ProgressExtensions.swift",
                            "MutationTesting/MutationTestingAbortReason.swift",
                            "Muter.swift",
                        ]
                    )
                )
            ]
        )
    }

    func test_whenLlvmCovFails_thenReturnEmpty() throws {
        let result = try XCTUnwrap(sut.run(with: state).get())

        XCTAssertEqual(result, [.projectCoverage(.null)])
    }

    func test_whenUnsupportedBuildSystem_thenReturnEmpty() throws {
        state.muterConfiguration = MuterConfiguration(
                executable: "/path/to/unsupported-build-system"
        )

        let result = try XCTUnwrap(sut.run(with: state))
        
        XCTAssertEqual(result, .success([.projectCoverage(.null)]))
        XCTAssertFalse(process.runCalled)
        XCTAssertFalse(process.waitUntilExitCalled)
    }
    
    func test_whenStepSucceeds_thenPostNotification() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["arg0", "arg1"]
        )

        process.stdoutToBeReturned = "something\nsomething\npath/to/testResult.xcresult"
        process.stdoutToBeReturned = "/path/to/xccov"
        process.stdoutToBeReturned = coverageData
        
        let expectation = expectation(
            forNotification: .projectCoverageDiscoveryFinished,
            object: true,
            notificationCenter: notificationCenter
        )
        
        _ = sut.run(with: state)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func test_whenStepFails_thenPostNotification() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["arg0", "arg1"]
        )

        process.stdoutToBeReturned = ""
        
        let expectation = expectation(
            forNotification: .projectCoverageDiscoveryFinished,
            object: false,
            notificationCenter: notificationCenter
        )
        
        _ = sut.run(with: state)
        
        wait(for: [expectation], timeout: 2)
    }
}

func loadLLVMCovLog() -> String {
    guard let data = FileManager.default.contents(atPath: "\(DiscoverProjectCoverageTests().fixturesDirectory)/logFromllvm-cov.txt"),
          let string = String(data: data, encoding: .utf8) else {
        fatalError("Unable to load reportfor testing")
    }
    
    return string
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
