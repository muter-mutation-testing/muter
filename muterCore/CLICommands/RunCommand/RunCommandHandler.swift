import Foundation

final class RunCommandHandler {
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
    
    func run() throws {
        try steps.forEach { step in
            try step.run(with: state).map(state.apply(_:)).get()
        }
    }
}

private extension RunCommandHandler {
    private static let defaultSteps: [RunCommandStep] = [
        LoadConfiguration(),
        CopyProjectToTempDirectory(),
        DiscoverSourceFiles(),
        DiscoverMutationPoints(),
        GenerateSwapFilePaths(),
        PerformMutationTesting()
    ]
}
