import SwiftSyntax

public struct MutationTestOutcome: Equatable {
    let testSuiteOutcome: TestSuiteOutcome
    let mutationPoint: MutationPoint
    let operatorDescription: String

    public init(testSuiteOutcome: TestSuiteOutcome,
                mutationPoint: MutationPoint,
                operatorDescription: String) {
        self.testSuiteOutcome = testSuiteOutcome
        self.mutationPoint = mutationPoint
        self.operatorDescription = operatorDescription
    }
}
