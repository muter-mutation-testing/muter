import Darwin
import Commandant
import muterCore

public func printHeader() {
    print(
        """


        _____       _
        |     | _ _ | |_  ___  ___
        | | | || | ||  _|| -_||  _|
        |_|_|_||___||_|  |___||_|


        Automated mutation testing for Swift

        You are running version \(version)

        Want help?
        https://github.com/SeanROlszewski/muter/issues
        +----------------------------------------------+

        """)
}

if #available(OSX 10.13, *) {
    printHeader()
    let stdoutObserver = StdoutObserver()
    let registry = CommandRegistry<MuterError>()
    registry
        .register(InitCommand())
        .register(RunCommand())
        .register(HelpCommand(registry: registry))
        .main(defaultVerb: RunCommand().verb) { (error) in
            print("Muter encountered an error: \n\(error)")
            exit(1)
    }
    
} else {
    print("Muter requires macOS 10.13 or higher")
    exit(1)
}
