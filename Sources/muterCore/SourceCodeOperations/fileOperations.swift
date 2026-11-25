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

/// Creates `<project>_muter_logs/<timestamp>` next to the project, the same way
/// the mutated copy is `<project>_mutated`. Never inside the project: a log
/// folder there is copied into the next run's mutated project and shows up as
/// untracked files in the user's repository.
func createLoggingDirectory(
    forProjectAt projectDirectory: String,
    fileManager: FileSystemManager = FileManager.default,
    locale: Locale = .autoupdatingCurrent,
    timestamp: () -> Date = Date.init
) -> String {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"

    // String path operations, not URL(fileURLWithPath:), which would resolve a
    // relative or `~` path against the current directory.
    let project = projectDirectory as NSString
    let logsRoot = (project.deletingLastPathComponent as NSString)
        .appendingPathComponent(project.lastPathComponent + "_muter_logs")
    let loggingDirectory = (logsRoot as NSString)
        .appendingPathComponent(formatter.string(from: timestamp()))
    try! fileManager.createDirectory(atPath: loggingDirectory, withIntermediateDirectories: true, attributes: nil)
    return loggingDirectory
}
