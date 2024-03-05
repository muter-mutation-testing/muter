import ArgumentParser
import Foundation

public struct RunWithoutMutating: RunCommand {
    public static let configuration = CommandConfiguration(
        commandName: "run-without-mutating",
        abstract: "Performs mutation testing using the test plan."
    )

    @OptionGroup var options: RunArguments
    @OptionGroup var reportOptions: ReportArguments

    @Argument(
        help: "The path for the test plan."
    )
    var testPlanURL: URL?

    public init() {}

    public func run() async throws {
        let options = RunOptions(
            reportFormat: reportOptions.reportFormat,
            reportURL: reportOptions.reportURL,
            skipCoverage: options.skipCoverage,
            skipUpdateCheck: options.skipUpdateCheck,
            configurationURL: options.configurationURL,
            testPlanURL: testPlanURL
        )

        try await run(with: options)
    }
}
