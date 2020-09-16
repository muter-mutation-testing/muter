import Commandant
import Result
import Curry
import Foundation

public struct RunCommand: CommandProtocol {

    public typealias Options = RunCommandOptions
    public typealias ClientError = MuterError
    public let verb: String = "run"
    public let function: String = """
    Performs mutation testing for the Swift project contained within the current directory

    Muter defaults to run when you don't specify any subcommands

    Available flags:

       --files-to-mutate    Only mutate a given list of source code files
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
    let filesToMutate: [String]
    
    public init(shouldOutputJSON: Bool, shouldOutputXcode: Bool, filesToMutate list: [String]) {
        if shouldOutputJSON {
            reporter = .json
        } else if shouldOutputXcode {
            reporter = .xcode
        } else {
            reporter = .plainText
        }
        
        filesToMutate = list
    }

    private static func create(_ shouldOutputJSON: Bool) -> (Bool) -> ([String]) -> RunCommandOptions {
        return { shouldOutputXcode in { filesToMutate in RunCommandOptions(shouldOutputJSON: shouldOutputJSON, shouldOutputXcode: shouldOutputXcode, filesToMutate: filesToMutate) } }
    }

    public static func evaluate(_ mode: CommandMode) -> Result<RunCommandOptions, CommandantError<ClientError>>  {
        return create
            <*> mode <| Option(key: "output-json", defaultValue: false, usage: "Whether or not Muter should output a json report after it's finished running.")
            <*> mode <| Option(key: "output-xcode", defaultValue: false, usage: "Whether or not Muter should output to Xcode after it's finished running.")
            <*> mode <| Option(
                key: "files-to-mutate",
                defaultValue: [],
                usage: """
                An exlusive list of files for Muter to work on.
                Please note that all subpaths are evalutated from the root of the project.
                """)
    }
}
