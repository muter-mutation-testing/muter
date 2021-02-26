import Foundation
import ArgumentParser

struct RunOptions {
    let reporter: Reporter
    let filesToMutate: [String]
    let skipCoverage: Bool
    
    init(
        shouldOutputJson: Bool,
        shouldOutputXcode: Bool,
        shouldOutputHtml: Bool,
        filesToMutate: [String],
        skipCoverage: Bool
    ) {
        self.filesToMutate = filesToMutate
        self.skipCoverage = skipCoverage
        self.reporter = {
            if shouldOutputJson { return JsonReporter() } else
            if shouldOutputXcode { return XcodeReporter() } else
            if shouldOutputHtml { return HTMLReporter() }

            return PlainTextReporter()
        }()
    }
}

public struct Run: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Performs mutation testing for the Swift project contained within the current directory"
    )

    @Option(help: "Only mutate a given list of source code files")
    var filesToMutate: [String] = []

    @Flag(
        name: [.customLong("output-json")],
        help: "Output test results to a json file."
    )
    var shouldOutputJson: Bool = false

    @Flag(
        name: [.customLong("output-html")],
        help: "Output test results to an html file."
    )
    var shouldOutputHtml: Bool = false

    @Flag(
        name: [.customLong("output-xcode")],
        help: "Output test results in a format consumable by an Xcode run script step."
    )
    var shouldOutputXcode: Bool = false
    
    @Flag(
        name: [.customLong("skip-coverage")],
        help: "Skips the step in which Muter runs your project in order to filter out files without coverage"
    )
    var skipCoverage: Bool = false

    public init() { }

    public func run() throws {
        let options = RunOptions(
            shouldOutputJson: shouldOutputJson,
            shouldOutputXcode: shouldOutputXcode,
            shouldOutputHtml: shouldOutputHtml,
            filesToMutate: filesToMutate,
            skipCoverage: skipCoverage
        )

        _ = RunCommandObserver(
            reporter: options.reporter,
            fileManager: FileManager.default,
            flushHandler: flushStdOut
        )

        NotificationCenter.default.post(name: .muterLaunched, object: nil)
        
        do {
            try RunCommandHandler(options: options).run()
        } catch {
            print(
                """
                ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  Muter has encountered an error  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️
                \(error)
                
                
                ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  See the Muter error log above this line  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️
                
                If you feel like this is a bug, or want help figuring out what could be happening, please open an issue at
                https://github.com/muter-mutation-testing/muter/issues
                """
            )
            
            Foundation.exit(-1)
        }
    }
}
