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
        state = RunCommandState(from: options)
    }

    func run() throws {
        try steps.forEach { step in
            try step.run(with: state).map(state.apply(_:)).get()
        }
    }
}

private extension RunCommandHandler {
    private static let defaultSteps: [RunCommandStep] = [
        UpdateCheck(),
        LoadConfiguration(),
        CreateTempDirectoryURL(),
        PreviousRunCleanUp(),
        CopyProjectToTempDirectory(),
        DiscoverProjectCoverage(),
        DiscoverSourceFiles(),
        DiscoverMutationPoints(),
        GenerateSwapFilePaths(),
        ApplySchemata(),
        BuildForTesting(),
        PerformMutationTesting(),
    ]
}

private extension [RunCommandStep] {
    func filter(with options: RunOptions) -> [Element] {
        exclude {
            options.skipCoverage && $0 is DiscoverProjectCoverage
        }
        .exclude {
            options.skipUpdateCheck && $0 is UpdateCheck
        }
    }
}
