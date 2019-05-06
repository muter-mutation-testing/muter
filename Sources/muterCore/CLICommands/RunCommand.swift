import Commandant
import Result
import Curry
import Foundation

@available(OSX 10.13, *)
public struct RunCommand: CommandProtocol {

    public typealias Options = RunCommandOptions
    public typealias ClientError = MuterError
    public let verb: String = "run"
    public let function: String = """
    Performs mutation testing for the Swift project contained within the current directory

    Muter defaults to run when you don't specify any subcommands

    Available flags:

       --output-json    Output test results to a json file
       --output-xcode   Output test results in a format consumable by an Xcode run script step

    """

    private let delegate: RunCommandIODelegate
    private let fileManager: FileSystemManager
    private let notificationCenter: NotificationCenter

    public init(delegate: RunCommandIODelegate = RunCommandDelegate(), fileManager: FileSystemManager = FileManager.default, notificationCenter: NotificationCenter = .default) {
        self.delegate = delegate
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
    }

    public func run(_ options: Options) -> Result<(), ClientError> {
        let _ = RunCommandObserver(reporter: options.reporter,
                                   fileManager: fileManager,
                                   flushHandler: flushStdOut)
        
        notificationCenter.post(name: .muterLaunched, object: nil)

        guard let configuration = delegate.loadConfiguration() else {
            return .failure(.configurationError)
        }

        delegate.backupProject(in: fileManager.currentDirectoryPath)
        delegate.executeTesting(using: configuration)

        return .success(())
    }
}

public struct RunCommandOptions: OptionsProtocol {
    public typealias ClientError = MuterError
    let reporter: Reporter
    
    public init(shouldOutputJSON: Bool, shouldOutputXcode: Bool) {
        if shouldOutputJSON {
            reporter = .json
        } else if shouldOutputXcode {
            reporter = .xcode
        } else {
            reporter = .plainText
        }
    }

    public static func evaluate(_ mode: CommandMode) -> Result<RunCommandOptions, CommandantError<ClientError>>  {
        return curry(self.init)
            <*> mode <| Option(key: "output-json", defaultValue: false, usage: "Whether or not Muter should output a json report after it's finished running.")
            <*> mode <| Option(key: "output-xcode", defaultValue: false, usage: "Whether or not Muter should output to Xcode after it's finished running.")
    }
}
