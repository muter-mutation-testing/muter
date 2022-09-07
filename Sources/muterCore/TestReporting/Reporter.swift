import Foundation

typealias MutationOutcomeWithFlush = (mutation: MutationTestOutcome.Mutation, fflush: () -> Void)

protocol Reporter {
    func newMutationTestOutcomeAvailable(outcomeWithFlush: MutationOutcomeWithFlush)
    func report(from outcome: MutationTestOutcome) -> String
}

extension Reporter {
    func newMutationTestOutcomeAvailable(outcomeWithFlush: MutationOutcomeWithFlush) { }
}
