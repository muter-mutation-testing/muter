import Foundation
@testable import muterCore

public extension MutationTestOutcome {
    init(testSuiteOutcome: TestSuiteOutcome,
         mutationPoint: MutationPoint,
         operatorDescription: String = "") {
        self.init(testSuiteOutcome: testSuiteOutcome,
                  mutationPoint: mutationPoint,
                  operatorDescription: operatorDescription,
                  originalProjectDirectoryUrl: URL(fileURLWithPath: ""))

    }
}
