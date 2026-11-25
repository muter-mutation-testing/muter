@testable import muterCore
import TestingExtensions
import XCTest

final class TestSuiteResultParsingTests: MuterTestCase {
    func test_logWithoutAnyError() {
        var contents = loadLogFile(named: "testRunWithoutFailures_withTestSucceededFooter.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .passed)

        contents = loadLogFile(named: "testRunWithoutFailures_withTestSucceededFooter_buckOutput.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .passed)
    }

    func test_logWithoutFailure() {
        var contents = loadLogFile(named: "testRunWithFailures_withoutTestFailedFooter.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .failed)

        contents = loadLogFile(named: "testRunWithFailures_swift.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .failed)

        contents = loadLogFile(named: "testRunWithFailures_withTestFailedFooter.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .failed)

        contents = loadLogFile(named: "testRunWithFailures_withTestFailedFooter_singleTestFailure.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .failed)

        contents = loadLogFile(named: "testRunWithFailures_withTestFailedFooter_noTestFailureCount.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .failed)

        contents = loadLogFile(named: "testRunWithFailures_withTestFailedFooter_buckOutput.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .failed)
    }

    func test_logWithFatalErrorAndErrorCodeZero() {
        let contents = loadLogFile(named: "runtimeError_fatalError.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .passed)
    }

    func test_logWithFatalErrorAndErrorCodeNotZero() {
        let contents = loadLogFile(named: "runtimeError_fatalError.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: -127), .runtimeError)
    }

    func test_logWithBuildError() {
        var contents = loadLogFile(named: "buildError_missingProjectFile.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .buildError)

        contents = loadLogFile(named: "buildError_runScriptStepFailed.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .buildError)

        contents = loadLogFile(named: "buildError_invalidSwiftCode.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .buildError)

        contents = loadLogFile(named: "buildError_withTestFailedFooter.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .buildError)

        contents = loadLogFile(named: "buildError_buckOutput.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .buildError)
    }

    private func loadLogFile(named name: String) -> String {
        guard let data = FileManager.default
            .contents(atPath: "\(fixturesDirectory)/TestLogsForParsing/\(name)"),
            let string = String(data: data, encoding: .utf8)
        else {
            fatalError("Unable to load a log file named \(name) for testing the XCTest result parser")
        }

        return string
    }

    // MARK: - Swift Testing

    func test_logWithSwiftTestingFailure() {
        var contents = loadLogFile(named: "testRunWithFailures_swiftTesting.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 1), .failed)

        contents = loadLogFile(named: "testRunWithFailures_swiftTesting_multipleIssues.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 1), .failed)
    }

    func test_logWithSwiftTestingSuccess() {
        let contents = loadLogFile(named: "testRunWithoutFailures_swiftTesting.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .passed)
    }

    func test_logWithSwiftTestingFailureAndExitCodeZero() {
        // Special case: log says "failed" even if exit code is 0
        let contents = loadLogFile(named: "testRunWithFailures_swiftTesting.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .failed)
    }

    func test_timedOutRunWithoutFailureOrCrash_isATimeout() {
        let log = "Test Suite 'All tests' started at 2026-11-25 11:48:27.092."

        XCTAssertEqual(
            TestSuiteOutcome.from(testLog: log, terminationStatus: 15, timeoutExecution: .timeout),
            .timeout
        )
    }

    func test_timedOutRunThatAlreadyCrashed_isARuntimeError() {
        let log = """
        Test Case '-[FFCParserCombinatorTests.FFCParserCombinatorTests testBacktrack]' passed (0.002 seconds).
        FFCParserCombinator/FFCParserCombinator.swift:105: Fatal error: Unexpectedly found nil while unwrapping an Optional value
        Restarting after unexpected exit, crash, or test timeout; summary will include totals from previous launches.
        """

        XCTAssertEqual(
            TestSuiteOutcome.from(testLog: log, terminationStatus: 15, timeoutExecution: .timeout),
            .runtimeError
        )
    }

    func test_timedOutSwiftTestRunThatAlreadyCrashed_isARuntimeError() {
        let log = "error: Exited with unexpected signal code 11"

        XCTAssertEqual(
            TestSuiteOutcome.from(testLog: log, terminationStatus: 15, timeoutExecution: .timeout),
            .runtimeError
        )
    }

    func test_timedOutRunThatAlreadyFailedATest_isAFailure() {
        let contents = loadLogFile(named: "testRunWithFailures_withoutTestFailedFooter.log")

        XCTAssertEqual(
            TestSuiteOutcome.from(testLog: contents, terminationStatus: 15, timeoutExecution: .timeout),
            .failed
        )
    }
}
