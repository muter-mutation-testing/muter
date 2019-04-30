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

// MARK - Working Directory
func createWorkingDirectory(in directory: String, fileManager: FileSystemManager = FileManager.default) -> String {
    let workingDirectory = "\(directory)/muter_tmp"
    try! fileManager.createDirectory(atPath: workingDirectory, withIntermediateDirectories: true, attributes: nil)
    return workingDirectory
}

// MARK - Logging Directory
func createLoggingDirectory(in directory: String, fileManager: FileSystemManager = FileManager.default) -> String {
    let logginDirectory = "\(directory)/\(Date().dateTime)"
    try! fileManager.createDirectory(atPath: logginDirectory, withIntermediateDirectories: true, attributes: nil)
    return logginDirectory
}

// MARK - Swap File Path
func swapFilePaths(forFilesAt paths: [String], using workingDirectoryPath: String) ->  [String: String] {
    var swapFilePathsByOriginalPath: [String: String] = [:]

    for path in paths {
        swapFilePathsByOriginalPath[path] = swapFilePath(forFileAt: path, using: workingDirectoryPath)
    }

    return swapFilePathsByOriginalPath
}

func swapFilePath(forFileAt path: String, using workingDirectory: String) -> String {
    let url = URL(fileURLWithPath: path)
    return "\(workingDirectory)/\(url.lastPathComponent)"
}
