import Darwin
import Foundation
import muterCore

if #available(OSX 10.13, *) {
    let configurationPath = FileManager.default.currentDirectoryPath + "/muter.conf.json"
    let configuration = try! JSONDecoder().decode(MuterConfiguration.self, from: FileManager.default.contents(atPath: configurationPath)!)

    run(with: configuration, in: FileManager.default.currentDirectoryPath)

    exit(0)
} else {
    print("Muter requires macOS 10.13 or higher")
    exit(1)
}
