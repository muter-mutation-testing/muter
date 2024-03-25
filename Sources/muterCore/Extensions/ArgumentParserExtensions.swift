import ArgumentParser
import Foundation

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self = argument.contains("/")
            ? URL(fileURLWithPath: argument)
            : URL(fileURLWithPath: current.fileManager.currentDirectoryPath + "/" + argument)
    }

    public var defaultValueDescription: String {
        path == FileManager.default.currentDirectoryPath && isFileURL
            ? "current directory"
            : String(describing: self)
    }
}
