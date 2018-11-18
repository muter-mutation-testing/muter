import SwiftSyntax
import Foundation

struct MuterConfiguration: Codable {
    let projectDirectory: String
    let testCommandArguments: [String]
    let testCommandExecutable: String
    
    enum CodingKeys: String, CodingKey {
        case projectDirectory = "projectDirectory"
        case testCommandArguments = "arguments"
        case testCommandExecutable = "executable"
    }
}

protocol FileSystemManager {
    func createDirectory(atPath path: String,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey : Any]?) throws
}

extension FileManager: FileSystemManager {}

struct FileParser {
    static func load(path: String) -> SourceFileSyntax? {
        let url = URL(fileURLWithPath: path)
        return try? SyntaxTreeParser.parse(url)
    }
    
    static func createWorkingDirectory(in directory: String, fileManager: FileSystemManager = FileManager.default) -> String {
        let workingDirectory = "\(directory)/muter_tmp"
        try! fileManager.createDirectory(atPath: workingDirectory, withIntermediateDirectories: true, attributes: nil)
        return workingDirectory
    }
    
    static func copySourceCode(fromFileAt sourcePath: String, to destinationPath: String) {
        let sourceCode = FileParser.load(path: sourcePath)
        try? sourceCode?.description.write(toFile: destinationPath, atomically: true, encoding: .utf8)
    }
    
    static func sourceFilesContained(in path: String) -> [String] {
        let subpaths = FileManager.default.subpaths(atPath: path) ?? []
        return subpaths
            .filter { $0.contains(".swift") }
            .map { "\(path)/\($0)"}
            .sorted()
    }
    
    static func swapFilePath(forFileAt path: String, using workingDirectory: String) -> String {
        guard let url = URL(string: path) else {
            return ""
        }
        return "\(workingDirectory)/\(url.lastPathComponent)"
    }
}


