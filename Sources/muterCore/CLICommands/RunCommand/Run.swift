import ArgumentParser
import Foundation

public struct Run: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Performs mutation testing for the Swift project contained within the current directory."
    )

    @Option(help: "Only mutate a given list of source code files.")
    var filesToMutate: [String] = []

    @Option(
        name: [.customShort("f"), .customLong("format")],
        help: "The report format for muter: \(ReportFormat.description)",
        transform: {
            guard let report = ReportFormat(rawValue: $0) else {
                throw MuterError.literal(reason: ReportFormat.description)
            }
            return report
        }
    )
    var reportFormat: ReportFormat = .plain

    @Option(
        name: [.customShort("c"), .customLong("configuration")],
        help: "The path to the muter configuration file."
    )
    var configurationURL: URL?

    @Option(
        name: [.customShort("o"), .customLong("output")],
        help: "Output file for the report to be saved."
    )
    var reportURL: URL?

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

    @Option(
        name: [.customShort("m"), .customLong("mappings")],
        help: "The path for the project schemata mappings."
    )
    var mappingsJsonURL: URL?

    @Flag(
        name: [.customLong("skip-coverage")],
        help: "Skips the step in which Muter runs your project in order to filter out files without coverage."
    )
    var skipCoverage: Bool = false

    @Flag(
        name: [.customLong("skip-update-check")],
        help: "Skips the step in which Muter checks for newer versions."
    )
    var skipUpdateCheck: Bool = false

    @Flag(
        name: [.customLong("generate-mappings")],
        help: "Run muter to create the mutated source code and save the mappings json for a later execution."
    )
    var generateMappings: Bool = false

    public init() {}

    public mutating func run() async throws {
        let mutationOperatorsList = !operators.isEmpty
            ? operators
            : .allOperators

        let options = RunOptions(
            filesToMutate: filesToMutate,
            reportFormat: reportFormat,
            reportURL: reportURL,
            mutationOperatorsList: mutationOperatorsList,
            skipCoverage: skipCoverage,
            skipUpdateCheck: skipUpdateCheck,
            configurationURL: configurationURL,
            mappingsJsonURL: mappingsJsonURL,
            generateMappings: generateMappings
        )

        _ = RunCommandObserver(
            runOptions: options
        )

        current.notificationCenter.post(name: .muterLaunched, object: nil)

        do {
            try await RunCommandHandler(options: options).run()
        } catch {
            print(
                """
                ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  Muter has encountered an error  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️
                \(error)


                ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  See the Muter error log above this line  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️

                If you think this is a bug, or want help figuring out what could be happening, please open an issue at
                https://github.com/muter-mutation-testing/muter/issues
                """
            )

            Foundation.exit(-1)
        }
    }
}

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self = argument.contains("/")
            ? URL(fileURLWithPath: argument)
            : URL(fileURLWithPath: current.fileManager.currentDirectoryPath + "/" + argument)
    }

    public var defaultValueDescription: String {
        path == FileManager.default.currentDirectoryPath && isFileURL
            ? "current directory"
            : String(describing: self)
    }
}
