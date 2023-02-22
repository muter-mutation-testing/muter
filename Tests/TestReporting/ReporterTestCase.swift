import XCTest
import TestingExtensions

@testable import muterCore

class ReporterTestCase: MuterTestCase {
    var outcomes = [
        MutationTestOutcome.Mutation.make(
            testSuiteOutcome: .passed,
            point: MutationPoint(
                mutationOperatorId: .ror,
                filePath: "/tmp/project/file3.swift",
                position: .firstPosition
            ),
            snapshot: MutationOperator.Snapshot(before: "!=", after: "==", description: "from != to =="),
            originalProjectDirectoryUrl: URL(string: "/user/project")!
        ),
    ]
}
