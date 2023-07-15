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

    @Flag(
        name: [.customLong("skip-coverage")],
        help: "Skips the step in which Muter runs your project in order to filter out files without coverage."
    )
    var skipCoverage: Bool = false

    @Option(
        name: [.customShort("o"), .customLong("output")],
        help: "Output file for the report to be saved."
    )
    var reportURL: URL?

    @Flag(
        name: [.customLong("skip-update-check")],
        help: "Skips the step in which Muter checks for newer versions."
    )
    var skipUpdateCheck: Bool = false

    public init() {}

    public mutating func run() async throws {
        let options = RunOptions(
            filesToMutate: filesToMutate,
            reportFormat: reportFormat,
            reportURL: reportURL,
            skipCoverage: skipCoverage,
            skipUpdateCheck: skipUpdateCheck
        )

        _ = RunCommandObserver(
            runOptions: options
        )

        NotificationCenter.default.post(name: .muterLaunched, object: nil)

        do {
            try await RunCommandHandler(options: options).run()
        } catch {
            Logger.print(
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
        guard let url = URL(string: argument) else {
            return nil
        }
        self = url
    }

    public var defaultValueDescription: String {
        path == FileManager.default.currentDirectoryPath && isFileURL
            ? "current directory"
            : String(describing: self)
    }
}
