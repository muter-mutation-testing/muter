import Foundation
import ArgumentParser

@available(macOS 10.13, *)
public struct Run: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Performs mutation testing for the Swift project contained within the current directory",
        discussion: "Muter defaults to run when you don't specify any subcommands"
    )

    @Argument(help: "Only mutate a given list of source code files")
    var filesToMutate: [String] = []

    @Flag(name: [.customLong("output-json")], help: "Output test results to a json file")
    var shouldOutputJson: Bool = false

    @Flag(name: [.customLong("output-xcode")], help: "Output test results in a format consumable by an Xcode run script step")
    var shouldOutputXcode: Bool = false

    private let fileManager: FileSystemManager
    private let notificationCenter: NotificationCenter

    public init(fileManager: FileSystemManager = FileManager.default,
                notificationCenter: NotificationCenter = .default) {
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
    }

    public init(from decoder: Decoder) throws {
        self.init(fileManager: FileManager.default, notificationCenter: .default)
    }

    public init() {
        self.init(fileManager: FileManager.default, notificationCenter: .default)
    }

    public func run() throws {
        try RunCommandHandler(command: self).handle()
    }
}
