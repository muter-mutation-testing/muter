import Foundation

func makeReporter(
    shouldOutputJson: Bool,
    shouldOutputXcode: Bool,
    shouldOutputHtml: Bool
) -> Reporter {
    if shouldOutputJson { return JsonReporter() } else
    if shouldOutputXcode { return XcodeReporter() } else
    if shouldOutputHtml { return HTMLReporter() }

    return PlainTextReporter()
}

typealias MutationOutcomeWithFlush = (mutation: MutationTestOutcome.Mutation, fflush: () -> Void)

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
    func mutationTestingFinished(mutationTestOutcome outcome: MutationTestOutcome)
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
    func mutationTestingFinished(mutationTestOutcome outcome: MutationTestOutcome) { }
}
