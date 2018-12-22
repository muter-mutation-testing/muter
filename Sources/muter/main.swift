import Darwin
import Foundation
import muterCore

if #available(OSX 10.13, *) {

    switch CommandLine.argc {
        case 2:
            guard CommandLine.arguments[1] == "init" else {
                print("Unrecognized subcommand given to Muter\nAvailable subcommands:\n\n\tinit")
                exit(1)
            }

            do {
                try setupMuter(using: FileManager.default, and: FileManager.default.currentDirectoryPath)
                print("Created muter config file at: \(FileManager.default.currentDirectoryPath)/muter.config.json")
                exit(0)
            } catch {
                print("Error creating muter config file\n\n\(error)")
                exit(1)
            }
            
        default: 
            let configurationPath = FileManager.default.currentDirectoryPath + "/muter.conf.json"
            let configuration = try! JSONDecoder().decode(MuterConfiguration.self, from: FileManager.default.contents(atPath: configurationPath)!)

            run(with: configuration, in: FileManager.default.currentDirectoryPath)
            exit(0)

    }


} else {
    print("Muter requires macOS 10.13 or higher")
    exit(1)
}
