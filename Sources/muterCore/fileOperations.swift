import SwiftSyntax
import Foundation

// MARK - Source Code
func sourceCode(fromFileAt path: String) -> SourceFileSyntax? {
    let url = URL(fileURLWithPath: path)
    return try? SyntaxTreeParser.parse(url)
}

func copySourceCode(fromFileAt sourcePath: String, to destinationPath: String) {
    let source = sourceCode(fromFileAt: sourcePath)
    try? source?.description.write(toFile: destinationPath, atomically: true, encoding: .utf8)
}

// MARK - Logging Directory
func createLoggingDirectory(in directory: String, fileManager: FileSystemManager = FileManager.default, timestamp: () -> Date = Date.init) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MM-HH-mm"
    let logginDirectory = "\(directory)/muter_logs/\(formatter.string(from: timestamp()))"
    try! fileManager.createDirectory(atPath: logginDirectory, withIntermediateDirectories: true, attributes: nil)
    return logginDirectory
}
