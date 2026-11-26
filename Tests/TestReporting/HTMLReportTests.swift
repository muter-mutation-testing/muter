@testable import muterCore
import TestingExtensions
import XCTest

final class HTMLReportTests: MuterTestCase {
    private let mutations: [MutationTestOutcome.Mutation] = (0 ... 50).map {
        let outcome = nextMutationTestOutcome($0)
        return MutationTestOutcome.Mutation.make(
            testSuiteOutcome: outcome,
            point: .make(
                mutationOperatorId: nextMutationOperator($0),
                filePath: "/root/file\($0).swift",
                position: .init(integerLiteral: $0)
            ),
            snapshot: .make(before: "before", after: "after"),
            originalProjectDirectoryUrl: URL(fileURLWithPath: "/root/"),
            failedTests: HTMLReportTests.failedTests(for: outcome, $0)
        )
    }

    private lazy var sut = HTMLReporter()

    /// Killed mutants make 1 to 3 tests fail, survivors 0; other outcomes have no count.
    private static func failedTests(for outcome: TestSuiteOutcome, _ index: Int) -> Int? {
        switch outcome {
        case .failed, .runtimeError: index % 3 + 1
        case .passed: 0
        default: nil
        }
    }

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
