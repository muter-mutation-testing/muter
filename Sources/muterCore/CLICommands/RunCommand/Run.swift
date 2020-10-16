import Foundation
import ArgumentParser

public struct Run: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Performs mutation testing for the Swift project contained within the current directory"
    )

    @Option(help: "Only mutate a given list of source code files")
    var filesToMutate: [String] = []

    @Flag(name: [.customLong("output-json")], help: "Output test results to a json file.")
    var shouldOutputJson: Bool = false

    @Flag(name: [.customLong("output-xcode")], help: "Output test results in a format consumable by an Xcode run script step.")
    var shouldOutputXcode: Bool = false

    public init() { }

    public func run() throws {
        _ = RunCommandObserver(
            reporter: makeReporter(
                shouldOutputJson: shouldOutputJson,
                shouldOutputXcode: shouldOutputXcode
            ),
            fileManager: FileManager.default,
            flushHandler: flushStdOut
        )

        NotificationCenter.default.post(name: .muterLaunched, object: nil)
        
        do {
            try RunCommandHandler(command: self).run()
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
