import ArgumentParser
import Foundation

public struct Run: RunCommand {
    public static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Performs mutation testing for the Swift project contained within the current directory."
    )

    @Option(help: "Only mutate a given list of source code files.")
    var filesToMutate: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: "The list of mutant operators to be used: \(MutationOperator.Id.description)",
        transform: {
            guard let `operator` = MutationOperator.Id(rawValue: $0) else {
                throw MuterError.literal(reason: MutationOperator.Id.description)
            }

            return `operator`
        }
    )
    var operators: [MutationOperator.Id] = MutationOperator.Id.allCases

    @OptionGroup var options: RunArguments
    @OptionGroup var reportOptions: ReportArguments

    public init() {}

    public func run() async throws {
        let mutationOperatorsList = !operators.isEmpty
            ? operators
            : .allOperators

        let options = RunOptions(
            filesToMutate: filesToMutate,
            reportFormat: reportOptions.reportFormat,
            reportURL: reportOptions.reportURL,
            mutationOperatorsList: mutationOperatorsList,
            skipCoverage: options.skipCoverage,
            skipUpdateCheck: options.skipUpdateCheck,
            configurationURL: options.configurationURL
        )

        try await run(with: options)
    }
}
