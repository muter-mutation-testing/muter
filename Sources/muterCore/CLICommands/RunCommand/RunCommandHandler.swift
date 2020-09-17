import Foundation

@available(OSX 10.13, *)
class RunCommandHandler {
    let steps: [RunCommandStep]
    var state: AnyRunCommandState

    init(steps: [RunCommandStep] = RunCommandHandler.defaultSteps,
         state: RunCommandState = .init()) {
        self.steps = steps
        self.state = state
    }
    
    init(command: Run,
         steps: [RunCommandStep] = RunCommandHandler.defaultSteps) {
        self.steps = steps
        self.state = RunCommandState(from: command)
    }
    
    func handle() throws {
        try steps.forEach {
            try $0.run(with: state).map(state.apply(_:)).get()
        }
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
