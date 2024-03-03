import Foundation

final class RunCommandHandler {
    let steps: [RunCommandStep]
    var state: AnyRunCommandState

    init(
        steps: [RunCommandStep] = RunCommandHandler.allSteps,
        state: RunCommandState = .init()
    ) {
        self.steps = steps
        self.state = state
    }

    convenience init(
        options: RunOptions,
        steps: [RunCommandStep] = RunCommandHandler.allSteps
    ) {
        self.init(
            steps: steps.filtering(with: options),
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
    private static let allSteps: [RunCommandStep] = [
        UpdateCheck(),
        LoadConfiguration(),
        CreateMutatedProjectDirectoryURL(),
        PreviousRunCleanUp(),
        CopyProjectToTempDirectory(),
        DiscoverProjectCoverage(),
        DiscoverSourceFiles(),
        DiscoverMutationPoints(),
        SaveProjectMappings(),
        GenerateSwapFilePaths(),
        ApplySchemata(),
        BuildForTesting(),
        ProjectMappings(),
        PerformMutationTesting(),
    ]
}

private extension [RunCommandStep] {
    func filtering(with options: RunOptions) -> [Element] {
        var copy = self
        if options.skipCoverage {
            copy.removeAll { $0 is DiscoverProjectCoverage }
        }
        if options.skipUpdateCheck {
            copy.removeAll { $0 is UpdateCheck }
        }
        if options.isUsingMappingsJson {
            copy.removeAll { $0 is CreateMutatedProjectDirectoryURL }
            copy.removeAll { $0 is PreviousRunCleanUp }
            copy.removeAll { $0 is CopyProjectToTempDirectory }
            copy.removeAll { $0 is DiscoverSourceFiles }
            copy.removeAll { $0 is DiscoverMutationPoints }
            copy.removeAll { $0 is GenerateSwapFilePaths }
            copy.removeAll { $0 is ApplySchemata }
            copy.removeAll { $0 is BuildForTesting }
            copy.removeAll { $0 is SaveProjectMappings }
        } else {
            copy.removeAll { $0 is ProjectMappings }
        }

        if options.generateMappings {
            return [
                LoadConfiguration(),
                CreateMutatedProjectDirectoryURL(),
                PreviousRunCleanUp(),
                CopyProjectToTempDirectory(),
                DiscoverProjectCoverage(),
                DiscoverSourceFiles(),
                DiscoverMutationPoints(),
                ApplySchemata(),
                SaveProjectMappings(),
            ]
        } else {
            copy.removeAll { $0 is SaveProjectMappings }
        }

        return copy
    }
}
