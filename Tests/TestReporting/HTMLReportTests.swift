@testable import muterCore
import SnapshotTesting
import SwiftSyntax
import TestingExtensions
import XCTest

final class HTMLReportTests: MuterTestCase {
    private let mutations: [MutationTestOutcome.Mutation] = (0 ... 50).map {
        MutationTestOutcome.Mutation.make(
            testSuiteOutcome: nextMutationTestOutcome($0),
            point: .make(
                mutationOperatorId: nextMutationOperator($0),
                filePath: "/root/file\($0).swift",
                position: .init(integerLiteral: $0)
            ),
            snapshot: .make(before: "before", after: "after"),
            originalProjectDirectoryUrl: URL(fileURLWithPath: "/root/")
        )
    }

    private lazy var sut = HTMLReporter()

    func test_reportWhenOutcomeHasCoverage() {
        let outcome = MutationTestOutcome.make(
            mutations: mutations,
            coverage: .make(percent: 78)
        )
        let actual = sut.report(from: outcome)

        AssertSnapshot(actual)
    }

    func test_reportWhenOutcomeDoesntHaveCoverage() {
        let outcome = MutationTestOutcome.make(
            mutations: mutations.exclude { $0.testSuiteOutcome == .noCoverage },
            coverage: .null
        )
        let actual = sut.report(from: outcome)

        AssertSnapshot(actual)
    }
}
