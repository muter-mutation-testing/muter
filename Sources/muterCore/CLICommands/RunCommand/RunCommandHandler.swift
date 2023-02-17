import Foundation

final class RunCommandHandler {
    let steps: [RunCommandStep]
    var state: AnyRunCommandState

    init(
        steps: [RunCommandStep] = RunCommandHandler.defaultSteps,
        state: RunCommandState = .init()
    ) {
        self.steps = steps
        self.state = state
    }
    
    init(
        options: RunOptions,
        steps: [RunCommandStep] = RunCommandHandler.defaultSteps
    ) {
        self.steps = steps.filter(with: options)
        self.state = RunCommandState(from: options)
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
        CreateTempDirectoryURL(),
        RemoveProjectFromPreviousRun(),
        CopyProjectToTempDirectory(),
        DiscoverProjectCoverage(),
        DiscoverSourceFiles(),
        DiscoverSchemataMutationMapping(),
        GenerateSwapFilePaths(),
        ApplySchemata(),
        BuildForTesting(),
        PerformMutationSchemataTesting(),
    ]
}

private extension Array where Element == RunCommandStep {
    func filter(with options: RunOptions) -> [Element] {
        exclude {
            options.skipCoverage && $0 is DiscoverProjectCoverage
        }
    }
}
