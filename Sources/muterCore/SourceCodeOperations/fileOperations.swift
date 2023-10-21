import Foundation
import SwiftParser
import SwiftSyntax

// MARK: - Source Code

func sourceCode(fromFileAt path: String) -> SourceCodeInfo? {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
          let source = String(data: data, encoding: .utf8)
    else {
        return nil
    }

    let code = Parser.parse(source: source)
    return SourceCodeInfo(
        path: path,
        code: code
    )
}

// MARK: - Logging Directory

func createLoggingDirectory(
    in directory: String,
    fileManager: FileSystemManager = FileManager.default,
    locale: Locale = .autoupdatingCurrent,
    timestamp: () -> Date = Date.init
) -> String {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"

    let loggingDirectory = "\(directory)/muter_logs/\(formatter.string(from: timestamp()))"
    try! fileManager.createDirectory(atPath: loggingDirectory, withIntermediateDirectories: true, attributes: nil)
    return loggingDirectory
}
