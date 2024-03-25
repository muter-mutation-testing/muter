import ArgumentParser
import Foundation

struct RunWithoutMutating: RunCommand {
    static let configuration = CommandConfiguration(
        commandName: "run-without-mutating",
        abstract: "Performs mutation testing using the test plan."
    )

    @OptionGroup var options: RunArguments
    @OptionGroup var reportOptions: ReportArguments

    @Argument(
        help: "The path for the test plan."
    )
    var testPlanURL: URL?

    init() {}

    func run() async throws {
        let options = Run.Options(
            reportFormat: reportOptions.reportFormat,
            reportURL: reportOptions.reportURL,
            skipCoverage: options.skipCoverage,
            skipUpdateCheck: options.skipUpdateCheck,
            configurationURL: options.configurationURL,
            testPlanURL: testPlanURL
        )

        try await run(with: options)
    }

    func validate() throws {
        if testPlanURL == nil {
            throw MuterError.literal(reason: "Please provide the path to the test plan json.")
        }
    }
}
