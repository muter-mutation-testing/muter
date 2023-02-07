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
        let initialTime = Date()

        try steps.forEach { step in
            try step.run(with: state).map(state.apply(_:)).get()
        }
        
        let timeAfterRunningTestSuite = Date()
        let timePerBuildTestCycle = DateInterval(
            start: initialTime,
            end: timeAfterRunningTestSuite
        ).duration
        
        Logger.print("Finished mutation tests")
        Logger.print("Took: \(timePerBuildTestCycle.stringFromTimeInterval())")
    }
}

extension TimeInterval{
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let ms = Int(truncatingRemainder(dividingBy: 1) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        
        return String(
            format: "%0.2d:%0.2d:%0.2d.%0.3d",
            hours,
            minutes,
            seconds,
            ms
        )
        
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
