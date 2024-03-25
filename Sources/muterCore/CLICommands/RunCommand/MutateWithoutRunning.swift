import ArgumentParser
import Foundation

struct MutateWithoutRunning: RunCommand {
    public static let configuration = CommandConfiguration(
        commandName: "mutate-without-running",
        abstract: "Mutates the source code and outputs the test plan as JSON."
    )

    @OptionGroup var options: RunArguments

    init() {}

    func run() async throws {
        let options = Run.Options(
            skipCoverage: options.skipCoverage,
            skipUpdateCheck: options.skipUpdateCheck,
            configurationURL: options.configurationURL,
            createTestPlan: true
        )

        try await run(with: options)
    }
}
