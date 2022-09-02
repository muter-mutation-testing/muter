import Foundation

typealias MutationOutcomeWithFlush = (mutation: MutationTestOutcome.Mutation, fflush: () -> Void)

protocol Reporter {
    func launched()
    func projectCopyStarted()
    func projectCopyFinished(destinationPath: String)
    func projectCoverageDiscoveryStarted()
    func projectCoverageDiscoveryFinished(success: Bool)
    func sourceFileDiscoveryStarted()
    func sourceFileDiscoveryFinished(sourceFileCandidates: [String])
    func mutationPointDiscoveryStarted()
    func mutationPointDiscoveryFinished(mutationPoints: [MutationPoint])
    func mutationTestingStarted()
    func newMutationTestOutcomeAvailable(outcomeWithFlush: MutationOutcomeWithFlush)
    func newMutationTestLogAvailable(mutationTestLog: MutationTestLog)
    func mutationTestingFinished(mutationTestOutcome outcome: MutationTestOutcome)
    func removeTempDirectoryStarted(path: String)
    func removeTempDirectoryFinished()
}

extension Reporter {
    func launched() { }
    func projectCopyStarted() { }
    func projectCopyFinished(destinationPath: String) { }
    func projectCoverageDiscoveryStarted() { }
    func projectCoverageDiscoveryFinished(success: Bool) { }
    func sourceFileDiscoveryStarted() { }
    func sourceFileDiscoveryFinished(sourceFileCandidates: [String]) { }
    func mutationPointDiscoveryStarted() { }
    func mutationPointDiscoveryFinished(mutationPoints: [MutationPoint]) { }
    func mutationTestingStarted() { }
    func newMutationTestOutcomeAvailable(outcomeWithFlush: MutationOutcomeWithFlush) { }
    func newMutationTestLogAvailable(mutationTestLog: MutationTestLog) { }
    func mutationTestingFinished(mutationTestOutcome outcome: MutationTestOutcome) { }
    func removeTempDirectoryStarted(path: String) { }
    func removeTempDirectoryFinished() { }
}
