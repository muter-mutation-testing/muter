@testable import muterCore
import XCTest

final class IgnoredMutantsReportTests: MuterTestCase {
    private let outcome = MutationTestOutcome.make(
        mutations: [
            .make(testSuiteOutcome: .failed, point: .make(mutationOperatorId: .ror, filePath: "/a.swift")),
            .make(testSuiteOutcome: .passed, point: .make(mutationOperatorId: .ror, filePath: "/a.swift")),
            .make(testSuiteOutcome: .ignored, point: .make(mutationOperatorId: .ror, filePath: "/a.swift")),
            .make(testSuiteOutcome: .ignored, point: .make(mutationOperatorId: .swapTernary, filePath: "/b.swift")),
        ]
    )

    func test_ignoredMutantsDoNotCountInTheScores() {
        let report = MuterTestReport(from: outcome)

        XCTAssertEqual(report.globalMutationScore, 50)
        XCTAssertEqual(report.fileReports.map(\.mutationScore), [50, 0])
    }

    func test_ignoredMutantsDoNotCountAsAppliedMutants() {
        let report = MuterTestReport(from: outcome)

        XCTAssertEqual(report.totalAppliedMutationOperators, 2)
        XCTAssertEqual(report.numberOfKilledMutants, 1)
        XCTAssertEqual(report.numberOfIgnoredMutants, 2)
    }

    func test_operatorReportsLeaveOutIgnoredMutants() {
        let report = MuterTestReport(from: outcome)

        XCTAssertEqual(report.operatorReports.map(\.mutationOperator), [.ror])
        XCTAssertEqual(report.operatorReports.first?.numberOfMutants, 2)
    }

    func test_fileReportsShowIgnoredMutants() {
        let report = MuterTestReport(from: outcome)

        XCTAssertEqual(
            report.fileReports.map { $0.appliedOperators.map(\.testSuiteOutcome) },
            [[.failed, .passed, .ignored], [.ignored]]
        )
    }

    func test_scoreIgnoresIgnoredMutants() {
        XCTAssertEqual(mutationScore(from: [.failed, .ignored, .ignored]), 100)
        XCTAssertEqual(mutationScore(from: [.ignored]), 0)
    }

    func test_plainTextReportCountsIgnoredMutants() {
        let report = PlainTextReporter().report(from: outcome)

        XCTAssertTrue(report.contains("2 mutants were ignored because of muter:disable comments."))
        XCTAssertTrue(report.contains("ignored (muter:disable)"))
    }

    func test_plainTextReportHasNoIgnoredLineWithoutIgnoredMutants() {
        let report = PlainTextReporter().report(from: .make(mutations: [.make(testSuiteOutcome: .failed)]))

        XCTAssertFalse(report.contains("were ignored"))
    }

    func test_jsonReportHasTheIgnoredCount() throws {
        let json = JsonReporter().report(from: outcome)
        let decoded = try JSONDecoder().decode(MuterTestReport.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.numberOfIgnoredMutants, 2)
    }

    func test_reportsWithoutTheIgnoredCountStillDecode() throws {
        let json = #"{"globalMutationScore":50,"totalAppliedMutationOperators":2,"numberOfKilledMutants":1,"fileReports":[],"timeElapsed":"00:00:00.000"}"#

        let decoded = try JSONDecoder().decode(MuterTestReport.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.numberOfIgnoredMutants, 0)
    }
}
