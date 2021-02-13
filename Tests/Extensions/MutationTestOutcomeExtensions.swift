import Foundation
@testable import muterCore

extension MutationTestOutcome.Mutation {
    static func make(
        testSuiteOutcome: TestSuiteOutcome,
        point: MutationPoint,
        snapshot: MutationOperatorSnapshot = .null
    ) -> MutationTestOutcome.Mutation {
        self.init(
            testSuiteOutcome: testSuiteOutcome,
            mutationPoint: point,
            mutationSnapshot: snapshot,
            originalProjectDirectoryUrl: URL(fileURLWithPath: "")
        )
    }
}
