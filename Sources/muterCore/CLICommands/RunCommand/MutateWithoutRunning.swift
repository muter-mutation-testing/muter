import ArgumentParser
import Foundation

public struct MutateWithoutRunning: RunCommand {
    public static let configuration = CommandConfiguration(
        commandName: "mutate-without-running",
        abstract: "Mutates the source code and outputs the test plan as JSON."
    )

    @OptionGroup var options: RunArguments

    public init() {}

    public func run() async throws {
        let options = RunOptions(
            skipCoverage: options.skipCoverage,
            skipUpdateCheck: options.skipUpdateCheck,
            configurationURL: options.configurationURL,
            createTestPlan: true
        )

        try await run(with: options)
    }
}
