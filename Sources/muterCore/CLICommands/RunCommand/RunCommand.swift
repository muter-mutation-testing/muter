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

       --files-to-mutate    Only mutate a given list of source code files
       --dry-run            Only list source files to be mutated, without actually runnning tests
       --output-json        Output test results to a json file
       --output-xcode       Output test results in a format consumable by an Xcode run script step

    """
    
    private let fileManager: FileSystemManager
    private let notificationCenter: NotificationCenter

    public init(fileManager: FileSystemManager = FileManager.default,
                notificationCenter: NotificationCenter = .default) {
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
    }

    public func run(_ options: Options) -> Result<(), ClientError> {
        let _ = RunCommandObserver(reporter: options.reporter,
                                   dryRun: options.dryRun,
                                   fileManager: fileManager,
                                   flushHandler: flushStdOut)
        
        notificationCenter.post(name: .muterLaunched, object: nil)

        let result = RunCommandHandler(options: options).handle()
        switch result {
        case .success(_):
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
}

public struct RunCommandOptions: OptionsProtocol {
    public typealias ClientError = MuterError
    let reporter: Reporter
    let dryRun: Bool
    let filesToMutate: [String]
    
    public init(shouldOutputJSON: Bool, shouldOutputXcode: Bool, dryRun: Bool, filesToMutate list: [String]) {
        if shouldOutputJSON {
            reporter = .json
        } else if shouldOutputXcode {
            reporter = .xcode
        } else {
            reporter = .plainText
        }

        self.dryRun = dryRun
        filesToMutate = list
    }

    public static func evaluate(_ mode: CommandMode) -> Result<RunCommandOptions, CommandantError<ClientError>>  {
        return curry(self.init)
            <*> mode <| Option(key: "output-json", defaultValue: false, usage: "Whether or not Muter should output a json report after it's finished running.")
            <*> mode <| Option(key: "output-xcode", defaultValue: false, usage: "Whether or not Muter should output to Xcode after it's finished running.")
            <*> mode <| Option(key: "dry-run", defaultValue: false, usage: "Whether or not Muter should just list files to mutate.")
            <*> mode <| Option(
                key: "files-to-mutate",
                defaultValue: [],
                usage: """
                An exclusive list of files for Muter to work on.
                Please note that all subpaths are evaluated from the root of the project.
                """)
    }
}
