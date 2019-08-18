import Commandant
import Result
import Foundation

@available(OSX 10.13, *)
public struct InitCommand: CommandProtocol {
    public typealias Options = NoOptions<MuterError>
    public typealias ClientError = MuterError
    public let verb: String = "init"
    public let function: String = "Creates the configuration file that Muter uses"

    private let directory: String
    private let fileManager: FileManager
    private let notificationCenter: NotificationCenter

    public init(directory: String = FileManager.default.currentDirectoryPath,
                fileManager: FileManager = FileManager.default,
                notificationCenter: NotificationCenter = .default) {
        self.directory = directory
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
    }

    public func run(_ options: Options) -> Result<(), ClientError> {
        notificationCenter.post(name: .muterLaunched, object: nil)

        let directoryContents = fileManager.subpaths(atPath: self.directory) ?? []
        fileManager.createFile(atPath: "\(self.directory)/muter.conf.json",
            contents: MuterConfiguration(from: directoryContents).asJSONData,
            attributes: nil)

        notificationCenter.post(name: .configurationFileCreated, object: "\(self.directory)/muter.conf.json")

        return Result.success(())
    }
}
