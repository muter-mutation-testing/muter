@testable import muterCore
import XCTest

final class FailedTestsTests: XCTestCase {
    func test_xcTest_usesTheWholeRunsCount() {
        let log = """
        Test Suite 'ParserTests' failed at 2026-11-26 10:00:00.000.
        \t Executed 4 tests, with 1 failure (0 unexpected) in 0.010 (0.011) seconds
        Test Suite 'StringTests' failed at 2026-11-26 10:00:00.000.
        \t Executed 7 tests, with 2 failures (0 unexpected) in 0.010 (0.011) seconds
        Test Suite 'All tests' failed at 2026-11-26 10:00:00.000.
        \t Executed 11 tests, with 3 failures (0 unexpected) in 0.020 (0.022) seconds
        """

        XCTAssertEqual(FailedTests.count(in: log), 3)
    }

    func test_xcTest_noFailures() {
        XCTAssertEqual(FailedTests.count(in: "\t Executed 11 tests, with 0 failures (0 unexpected) in 0.020 seconds"), 0)
    }

    func test_xcTest_afterACrashRestart_usesTheTotals() {
        let log = """
        Restarting after unexpected exit, crash, or test timeout; summary will include totals from previous launches.
        \t Executed 1 test, with 1 failure (1 unexpected) in 0.001 (0.001) seconds
        \t Executed 11 tests, with 2 failures (1 unexpected) in 0.020 (0.022) seconds
        """

        XCTAssertEqual(FailedTests.count(in: log), 2)
    }

    func test_swiftTesting_countsFailedTestsOnce() {
        let log = """
        ✘ Test parsesNumbers() recorded an issue at ParserTests.swift:12:5: Expectation failed
        ✘ Test parsesNumbers() failed after 0.002 seconds with 2 issues.
        ✔ Test parsesWords() passed after 0.001 seconds.
        ✘ Test trimsSpaces() failed after 0.001 seconds with 1 issue.
        ✘ Test run with 3 tests in 1 suite failed after 0.004 seconds with 3 issues.
        """

        XCTAssertEqual(FailedTests.count(in: log), 2)
    }

    func test_swiftTesting_passingRun() {
        XCTAssertEqual(FailedTests.count(in: "✔ Test run with 3 tests in 1 suite passed after 0.004 seconds."), 0)
    }

    func test_bothFrameworks_addUp() {
        let log = """
        \t Executed 5 tests, with 1 failure (0 unexpected) in 0.010 (0.011) seconds
        ✘ Test trimsSpaces() failed after 0.001 seconds with 1 issue.
        ✘ Test run with 2 tests in 1 suite failed after 0.004 seconds with 1 issue.
        """

        XCTAssertEqual(FailedTests.count(in: log), 2)
    }

    func test_logWithoutASummary_isUnknown() {
        XCTAssertNil(FailedTests.count(in: "error: cannot find 'foo' in scope\n** TEST BUILD FAILED **"))
    }
}
