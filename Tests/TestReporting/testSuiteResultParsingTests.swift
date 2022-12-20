import XCTest

@testable import muterCore

final class TestSuiteResultParsingTests: XCTestCase {
    func test_logWithoutAnyError() {
        var contents = loadLogFile(named: "testRunWithoutFailures_withTestSucceededFooter.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .passed)

        contents = loadLogFile(named: "testRunWithoutFailures_withTestSucceededFooter_buckOutput.log")
        XCTAssertEqual(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0), .passed)
    }

    func test_logWithoutFailure() {
        var contents = loadLogFile(named: "testRunWithFailures_withoutTestFailedFooter.log")
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
}

private func loadLogFile(named name: String) -> String {
    guard let data = FileManager.default.contents(atPath: "\(TestSuiteResultParsingTests().fixturesDirectory)/TestLogsForParsing/\(name)"),
        let string = String(data: data, encoding: .utf8) else {
            fatalError("Unable to load a log file named \(name) for testing the XCTest result parser")
    }

    return string
}
