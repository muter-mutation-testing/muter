@available(OSX 10.13, *)
class RunCommandHandler {
    let steps: [RunCommandStep]
    var state: RunCommandState

    init(steps: [RunCommandStep] = RunCommandHandler.defaultSteps,
         state: RunCommandState = .init()) {
        self.steps = steps
        self.state = state
    }
    
    func handle() -> Result<(), MuterError> {
        for step in steps {
            let result = step.run(with: state)

            switch result {
            case .failure(let error):
                    return .failure(error)
            case .success(let stateChanges):
                for change in stateChanges {
                    change.apply(to: &state)
                }
            }
        }
        return .success(())
    }
}

@available(OSX 10.13, *)
private extension RunCommandHandler {
    private static let defaultSteps: [RunCommandStep] = [LoadConfiguration(),
                                                         CopyProjectToTempDirectory(),
                                                         DiscoverSourceFiles(),
                                                         DiscoverMutationPoints(),
                                                         GenerateSwapFilePaths(),
                                                         PerformMutationTesting()]
}
