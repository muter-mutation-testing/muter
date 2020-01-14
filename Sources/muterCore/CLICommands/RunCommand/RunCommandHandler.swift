@available(OSX 10.13, *)
class RunCommandHandler {
    let steps: [RunCommandStep]
    var state: AnyRunCommandState

    init(steps: [RunCommandStep] = RunCommandHandler.defaultSteps,
         state: RunCommandState = .init()) {
        self.steps = steps
        self.state = state
    }
    
    init(options: RunCommandOptions) {
        self.steps = options.dryRun ? RunCommandHandler.dryRunSteps : RunCommandHandler.defaultSteps
        self.state = RunCommandState(from: options)
    }
    
    func handle() -> Result<(), MuterError> {
        for step in steps {
            let result = step.run(with: state)

            switch result {
            case .failure(let error):
                return .failure(error)
            case .success(let stateChanges):
                state.apply(stateChanges)
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
    private static let dryRunSteps: [RunCommandStep] = [LoadConfiguration(),
                                                        DiscoverSourceFiles(),
                                                        DiscoverMutationPoints()]
}
