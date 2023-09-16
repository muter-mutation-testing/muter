import ArgumentParser
import Foundation

public struct Init: AsyncParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Creates the configuration file that Muter uses"
    )

    private let directory: String
    private let fileManager: FileManager
    private let notificationCenter: NotificationCenter

    public init(
        directory: String = FileManager.default.currentDirectoryPath,
        fileManager: FileManager = FileManager.default,
        notificationCenter: NotificationCenter = .default
    ) {
        self.directory = directory
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
    }

    public init(from decoder: Decoder) throws {
        self.init(
            directory: FileManager.default.currentDirectoryPath,
            fileManager: .default,
            notificationCenter: .default
        )
    }

    public init() {
        self.init(
            directory: FileManager.default.currentDirectoryPath,
            fileManager: .default,
            notificationCenter: .default
        )
    }

    public mutating func run() async throws {
        notificationCenter.post(name: .muterLaunched, object: nil)

        let directoryContents = fileManager.subpaths(atPath: directory) ?? []
        fileManager.createFile(
            atPath: "\(directory)/\(MuterConfiguration.fileNameWithExtension)",
            contents: MuterConfiguration(from: directoryContents).asData,
            attributes: nil
        )

        notificationCenter.post(
            name: .configurationFileCreated,
            object: "\(directory)/\(MuterConfiguration.fileNameWithExtension)"
        )
    }
}
