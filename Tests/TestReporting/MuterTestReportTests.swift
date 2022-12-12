import XCTest

@testable import muterCore

final class MuterTestReportTests: XCTestCase {
    func test_calculatingNonEmptyTestOutcomes() {
        let outcome =
            MutationTestOutcome.make(
                mutations:
                    exampleMutationTestResults + [
                        MutationTestOutcome.Mutation.make(
                            testSuiteOutcome: .failed,
                            point: MutationPoint(
                                mutationOperatorId: .ror,
                                filePath: "/tmp/a module.swift",
                                position: .firstPosition
                            ),
                            snapshot: .make(
                                before: "==",
                                after: "!=",
                                description: "changed from == to !="
                            )
                        ),
                    ]
            )

        let report = MuterTestReport(from: outcome)

        XCTAssertEqual(report.globalMutationScore, 60)
        XCTAssertEqual(report.totalAppliedMutationOperators, 10)
        XCTAssertEqual(report.fileReports.count, 5)
        XCTAssertEqual(report.fileReports, [
            FileReportProvider.expectedFileReport1,
            FileReportProvider.expectedFileReport2,
            FileReportProvider.expectedFileReport3,
            FileReportProvider.expectedFileReport4,
            FileReportProvider.expectedFileReport5,
        ])
    }

    func test_calculatingEmptyTestOutcomes() {
        let report = MuterTestReport(from: .make())

        XCTAssertEqual(report.globalMutationScore, -1)
        XCTAssertEqual(report.totalAppliedMutationOperators, 0)
        XCTAssertTrue(report.fileReports.isEmpty)
    }

    func test_mutationScore() {
        let expectedMutationScores = [
            "/tmp/file1.swift": 66,
            "/tmp/file2.swift": 100,
            "/tmp/file3.swift": 33,
            "/tmp/file 4.swift": 0,
        ]

        let actualMutationScores = mutationScoresOfFiles(from: exampleMutationTestResults)

        XCTAssertEqual(actualMutationScores, expectedMutationScores)
    }
}
