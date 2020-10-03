import Foundation

func makeReporter(shouldOutputJson: Bool, shouldOutputXcode: Bool) -> Reporter {
    if shouldOutputJson {
        return JsonReporter()
    }
    else if shouldOutputXcode {
        return XcodeReporter()
    }
    else {
        return PlainTextReporter()
    }
}

typealias MutationOutcomeWithFlush = (outcome: MutationTestOutcome, fflush: () -> Void)

protocol Reporter {
    func launched()
    func projectCopyStarted()
    func projectCopyFinished(destinationPath: String)
    func sourceFileDiscoveryStarted()
    func sourceFileDiscoveryFinished(sourceFileCandidates: [String])
    func mutationPointDiscoveryStarted()
    func mutationPointDiscoveryFinished(mutationPoints: [MutationPoint])
    func mutationTestingStarted()
    func newMutationTestOutcomeAvailable(outcomeWithFlush: MutationOutcomeWithFlush)
    func newMutationTestLogAvailable(mutationTestLog: MutationTestLog)
    func mutationTestingFinished(mutationTestOutcomes outcomes: [MutationTestOutcome])
}

extension Reporter {
    func launched() { }
    func projectCopyStarted() { }
    func projectCopyFinished(destinationPath: String) { }
    func sourceFileDiscoveryStarted() { }
    func sourceFileDiscoveryFinished(sourceFileCandidates: [String]) { }
    func mutationPointDiscoveryStarted() { }
    func mutationPointDiscoveryFinished(mutationPoints: [MutationPoint]) { }
    func mutationTestingStarted() { }
    func newMutationTestOutcomeAvailable(outcomeWithFlush: MutationOutcomeWithFlush) { }
    func newMutationTestLogAvailable(mutationTestLog: MutationTestLog) { }
    func mutationTestingFinished(mutationTestOutcomes outcomes: [MutationTestOutcome]) { }
}
