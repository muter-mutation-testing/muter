import Foundation

final class RunCommandHandler {
    let steps: [RunCommandStep]
    let traps: [RunCommandTrap]
    var state: AnyRunCommandState

    init(
        steps: [RunCommandStep] = RunCommandHandler.defaultSteps,
        traps: [RunCommandTrap] = RunCommandHandler.defaultTraps,
        state: RunCommandState = .init()
    ) {
        self.steps = steps
        self.traps = traps
        self.state = state
    }
    
    init(
        options: RunOptions,
        steps: [RunCommandStep] = RunCommandHandler.defaultSteps,
        traps: [RunCommandTrap] = RunCommandHandler.defaultTraps
    ) {
        self.steps = steps.filter(with: options)
        self.traps = traps
        self.state = RunCommandState(from: options)
    }
    
    func run() throws {
        try steps.forEach { step in
            try step.run(with: state).map(state.apply(_:)).get()
        }
    }
    
    func trap() {
        traps.forEach { trap in
            trap.run(with: state)
        }
    }
}

private extension RunCommandHandler {
    private static let defaultSteps: [RunCommandStep] = [
        LoadConfiguration(),
        CopyProjectToTempDirectory(),
        DiscoverProjectCoverage(),
        DiscoverSourceFiles(),
        DiscoverMutationPoints(),
        GenerateSwapFilePaths(),
        PerformMutationTesting(),
        RemoveTempDirectory()
    ]
    
    private static let defaultTraps: [RunCommandTrap] = [
        RemoveTempDirectory()
    ]
}

private extension Array where Element == RunCommandStep {
    func filter(with options: RunOptions) -> [Element] {
        exclude {
            options.skipCoverage && $0 is DiscoverProjectCoverage
        }
    }
}
