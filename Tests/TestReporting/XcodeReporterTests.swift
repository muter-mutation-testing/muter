@testable import muterCore
import TestingExtensions
import XCTest

final class XcodeReporterTests: ReporterTestCase {
    override func setUp() {
        super.setUp()

        outcomes.append(contentsOf: [
            MutationTestOutcome.Mutation.make(
                testSuiteOutcome: .failed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/project/file4.swift",
                    position: .firstPosition
                ),
                snapshot: MutationOperator.Snapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                originalProjectDirectoryUrl: URL(string: "/user/project")!
            ),
            MutationTestOutcome.Mutation.make(
                testSuiteOutcome: .passed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/project/file5.swift",
                    position: .firstPosition
                ),
                snapshot: MutationOperator.Snapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                ),
                originalProjectDirectoryUrl: URL(string: "/user/project")!
            ),
        ])
    }

    func test_report() {
        let actualReport = XcodeReporter()
            .report(
                from: .make(mutations: outcomes)
            )

        XCTAssertEqual(
            actualReport,
            """
            Mutation score: 33
            Mutants introduced into your code: 3
            Number of killed mutants: 1
            """
        )
    }
}
