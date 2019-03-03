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
    Performs mutation testing for the Swift project contained within the current directory.
    
    Available flags:

       --output-json    Output test results to a json file
       --output-xcode   Output test results in a format consumable by an Xcode run script step

    """

    private let delegate: RunCommandIODelegate
    private let currentDirectory: String
    public init(delegate: RunCommandIODelegate = RunCommandDelegate(),
                currentDirectory: String = FileManager.default.currentDirectoryPath) {
        self.delegate = delegate
        self.currentDirectory = currentDirectory
    }

    public func run(_ options: Options) -> Result<(), ClientError> {
        
        guard let configuration = delegate.loadConfiguration() else {
            return .failure(.configurationError)
        }

        delegate.backupProject(in: currentDirectory)
        delegate
            .executeTesting(using: configuration)
            .map {
                print(options.reporter($0))
            }

        return .success(())
    }
}

public struct RunCommandOptions: OptionsProtocol {
    public typealias ClientError = MuterError
    let reporter: Reporter
    
    public init(shouldOutputJSON: Bool, shouldOutputXcode: Bool) {
        if shouldOutputJSON  {
            reporter = jsonReporter
        } else if shouldOutputXcode {
            reporter = xcodeReporter
        } else {
            reporter = textReporter
        }
    }

    public static func evaluate(_ mode: CommandMode) -> Result<RunCommandOptions, CommandantError<ClientError>>  {
        return curry(self.init)
            <*> mode <| Option(key: "output-json", defaultValue: false, usage: "Whether or not Muter should output a json report after it's finished running.")
            <*> mode <| Option(key: "output-xcode", defaultValue: false, usage: "Whether or not Muter should output to Xcode after it's finished running.")
    }
}
