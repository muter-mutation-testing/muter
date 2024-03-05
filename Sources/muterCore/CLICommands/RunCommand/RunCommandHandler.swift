import Foundation

final class RunCommandHandler {
    @Dependency(\.notificationCenter)
    private var notificationCenter

    let steps: [RunCommandStep]
    var state: AnyRunCommandState

    private let options: RunOptions

    init(
        options: RunOptions = .null,
        steps: [RunCommandStep] = .allSteps,
        state: RunCommandState = .init()
    ) {
        self.steps = steps
        self.state = state
        self.options = options
    }

    convenience init(
        options: RunOptions,
        steps: [RunCommandStep] = .allSteps
    ) {
        self.init(
            options: options,
            steps: steps.filtering(with: options),
            state: RunCommandState(from: options)
        )
    }

    func run() async throws {
        startObserver()
        notifyMuterLaunched()
        try await runMutationsSteps()
    }

    private func startObserver() {
        _ = RunCommandObserver(runOptions: options)
    }

    private func notifyMuterLaunched() {
        notificationCenter.post(name: .muterLaunched, object: nil)
    }

    private func runMutationsSteps() async throws {
        for step in steps {
            let changes = try await step.run(with: state)
            state.apply(changes)
        }
    }
}

private extension [RunCommandStep] {
    static let allSteps: [RunCommandStep] = [
        UpdateCheck(),
        LoadConfiguration(),
        CreateMutatedProjectDirectoryURL(),
        PreviousRunCleanUp(),
        CopyProjectToTempDirectory(),
        DiscoverProjectCoverage(),
        DiscoverSourceFiles(),
        DiscoverMutationPoints(),
        SaveMuterTestPlan(),
        GenerateSwapFilePaths(),
        ApplySchemata(),
        BuildForTesting(),
        ProjectMappings(),
        PerformMutationTesting(),
    ]

    static let testPlanSteps: [RunCommandStep] = [
        UpdateCheck(),
        LoadConfiguration(),
        DiscoverProjectCoverage(),
        BuildForTesting(),
        ProjectMappings(),
        PerformMutationTesting(),
    ]

    static let createTestPlanSteps: [RunCommandStep] = [
        UpdateCheck(),
        LoadConfiguration(),
        CreateMutatedProjectDirectoryURL(),
        PreviousRunCleanUp(),
        CopyProjectToTempDirectory(),
        DiscoverProjectCoverage(),
        DiscoverSourceFiles(),
        DiscoverMutationPoints(),
        ApplySchemata(),
        SaveMuterTestPlan(),
    ]

    func filtering(with options: RunOptions) -> [RunCommandStep] {
        var copy: [any RunCommandStep] = self

        if options.isUsingTestPlan {
            copy = [RunCommandStep].testPlanSteps
        } else {
            copy.removeAll { $0 is ProjectMappings }
        }

        if options.createTestPlan {
            copy = [RunCommandStep].createTestPlanSteps
        } else {
            copy.removeAll { $0 is SaveMuterTestPlan }
        }

        if options.skipCoverage {
            copy.removeAll { $0 is DiscoverProjectCoverage }
        }
        if options.skipUpdateCheck {
            copy.removeAll { $0 is UpdateCheck }
        }

        return copy
    }
}
