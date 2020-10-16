import Foundation
@testable import muterCore

public extension MutationTestOutcome {
    init(testSuiteOutcome: TestSuiteOutcome,
         mutationPoint: MutationPoint,
         mutationSnapshot: MutationOperatorSnapshot = .null) {
        self.init(testSuiteOutcome: testSuiteOutcome,
                  mutationPoint: mutationPoint,
                  mutationSnapshot: mutationSnapshot,
                  originalProjectDirectoryUrl: URL(fileURLWithPath: ""))
        
    }
}
