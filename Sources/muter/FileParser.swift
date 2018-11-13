import SwiftSyntax
import Foundation

struct FileParser {
    static func load(path: String) -> SourceFileSyntax {
        let url = URL(fileURLWithPath: path)
        return try! SyntaxTreeParser.parse(url)
    }
    
    static func createWorkingDirectory(in directory: String) -> String {
        let workingDirectory = "\(directory)/muter_tmp/"
            try! FileManager.default.createDirectory(atPath: workingDirectory, withIntermediateDirectories: true, attributes: nil)
        return workingDirectory
    }
    
    static func copySourceCode(fromFileAt sourcePath: String, to destinationPath: String) {
        let sourceCode = FileParser.load(path: sourcePath)
        try! sourceCode.description.write(toFile: destinationPath, atomically: true, encoding: .utf8)
    }
}
