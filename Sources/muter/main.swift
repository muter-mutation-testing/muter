import Darwin
import Foundation
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

enum MuterError: Error {
    case configurationError
}

if #available(OSX 10.13, *) {

    printHeader()

    let fileManager = FileManager.default
    let currentDirectoryPath = fileManager.currentDirectoryPath

    let (exitCode, message) = handle(
        commandlineArguments: CommandLine.arguments,
        setup: {
            try setupMuter(using: fileManager, and: currentDirectoryPath)
    },
        run: { flag in
            let configurationPath = currentDirectoryPath + "/muter.conf.json"

            guard let configurationData = fileManager.contents(atPath: configurationPath) else {
                throw MuterError.configurationError
            }

            let configuration = try JSONDecoder().decode(MuterConfiguration.self, from: configurationData)
            run(with: configuration, flag: flag, in: currentDirectoryPath)
    }
    )

    print(message ?? "")
    exit(exitCode)
} else {
    print("Muter requires macOS 10.13 or higher")
    exit(1)
}
