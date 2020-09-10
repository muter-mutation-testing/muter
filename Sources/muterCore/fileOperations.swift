import SwiftSyntax
import Foundation

// MARK - Source Code

func sourceCode(fromFileAt path: String) -> SourceCodeInfo? {
    let url = URL(fileURLWithPath: path)
    return (try? SyntaxParser.parse(url))
        .map { (code: $0, path: url.absoluteString) }
        .map (SourceCodeInfo.init)
}

// MARK - Logging Directory
func createLoggingDirectory(in directory: String,
                            fileManager: FileSystemManager = FileManager.default,
                            locale: Locale = .autoupdatingCurrent,
                            timestamp: () -> Date = Date.init) -> String {
    
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    
    let loggingDirectory = "\(directory)/muter_logs/\(formatter.string(from: timestamp()))"
    try! fileManager.createDirectory(atPath: loggingDirectory, withIntermediateDirectories: true, attributes: nil)
    return loggingDirectory
}

public struct SourceCodeInfo {
    let code: SourceFileSyntax
    let path: String
}
