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

    convenience init(
        options: RunOptions,
        steps: [RunCommandStep] = RunCommandHandler.defaultSteps
    ) {
        self.init(
            steps: steps.filter(with: options),
            state: RunCommandState(from: options)
        )
    }

    func run() async throws {
        for step in steps {
            let changes = try await step.run(with: state)
            state.apply(changes)
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
