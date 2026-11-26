@testable import muterCore
import XCTest

final class MuterTestReportFailedTestsTests: XCTestCase {
    private func mutant(_ id: MutationOperator.Id, _ outcome: TestSuiteOutcome, failedTests: Int?) -> MutationTestOutcome.Mutation {
        MutationTestOutcome.Mutation(
            testSuiteOutcome: outcome,
            mutationPoint: MutationPoint(mutationOperatorId: id, filePath: "/project/File.swift", position: .null),
            mutationSnapshot: .null,
            originalProjectDirectoryUrl: URL(fileURLWithPath: "/project"),
            mutatedProjectDirectoryURL: URL(fileURLWithPath: "/project_mutated"),
            failedTests: failedTests
        )
    }

    private lazy var report = MuterTestReport(from: MutationTestOutcome(mutations: [
        mutant(.ror, .failed, failedTests: 3),
        mutant(.ror, .passed, failedTests: 0),
        mutant(.ror, .buildError, failedTests: nil),
        mutant(.removeSideEffects, .failed, failedTests: 1),
    ]))

    func test_operatorReports_totalsAndAverages() {
        XCTAssertEqual(report.operatorReports, [
            .init(mutationOperator: .ror, numberOfMutants: 3, numberOfKilledMutants: 1, numberOfFailedTests: 3, averageNumberOfFailedTests: 1.5),
            .init(mutationOperator: .removeSideEffects, numberOfMutants: 1, numberOfKilledMutants: 1, numberOfFailedTests: 1, averageNumberOfFailedTests: 1),
        ])
    }

    func test_averageNumberOfFailedTests_leavesOutUnknownCounts() {
        // (3 + 0 + 1) / 3: the build error has no count.
        XCTAssertEqual(report.averageNumberOfFailedTests, 1.33)
    }

    func test_averageNumberOfFailedTests_isNilWithoutCounts() {
        let report = MuterTestReport(from: MutationTestOutcome(mutations: [mutant(.ror, .buildError, failedTests: nil)]))

        XCTAssertNil(report.averageNumberOfFailedTests)
        XCTAssertNil(report.operatorReports.first?.averageNumberOfFailedTests)
    }

    func test_json_hasTheCountOnlyWhenKnown() throws {
        let json = try XCTUnwrap(String(data: JSONEncoder().encode(report), encoding: .utf8))

        // The ROR operator report and the failed ROR mutant both have 3.
        XCTAssertEqual(json.components(separatedBy: "\"numberOfFailedTests\":3").count, 3, json)
        XCTAssertTrue(json.contains("\"averageNumberOfFailedTests\":1.33"), json)

        let decoded = try JSONDecoder().decode(MuterTestReport.self, from: Data(json.utf8))
        let counts = decoded.fileReports.flatMap(\.appliedOperators).map(\.numberOfFailedTests)
        XCTAssertEqual(counts.compactMap { $0 }.sorted(), [0, 1, 3])
        XCTAssertEqual(counts.filter { $0 == nil }.count, 1)
    }

    func test_olderJsonReportsStillDecode() throws {
        let json = """
        {"globalMutationScore": 50, "totalAppliedMutationOperators": 2, "numberOfKilledMutants": 1,
         "fileReports": [], "timeElapsed": "00:00:01.000"}
        """

        let decoded = try JSONDecoder().decode(MuterTestReport.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.operatorReports, [])
        XCTAssertNil(decoded.averageNumberOfFailedTests)
    }
}
