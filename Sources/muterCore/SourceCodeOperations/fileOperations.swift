import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxParser

// MARK: - Source Code

func sourceCode(fromFileAt path: String) -> SourceCodeInfo? {
    guard let fileContents = FileManager.default.contents(atPath: path),
          let sourceFile = String(data: fileContents, encoding: .utf8) else {
        return nil
    }

    let sourceCode = Parser.parse(source: sourceFile)
    return SourceCodeInfo(
        path: path,
        code: sourceCode
    )
}

// MARK: - Logging Directory
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
