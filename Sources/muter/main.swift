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

    CommandRegistry<MuterError>()
        .register(InitCommand())
        .register(RunCommand())
        .main(defaultVerb: RunCommand().verb) { (error) in
            print("Muter encountered an error: \n\(error)")
            exit(1)
    }

} else {
    print("Muter requires macOS 10.13 or higher")
    exit(1)
}
