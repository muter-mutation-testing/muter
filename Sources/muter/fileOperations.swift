import SwiftSyntax
import Foundation

private let defaultBlacklist = ["Build", "muter_tmp", "Tests", "Pods", "Carthage", ".swiftmodule", ".framework", "Spec"]

func sourceCode(fromFileAt path: String) -> SourceFileSyntax? {
    let url = URL(fileURLWithPath: path)
    return try? SyntaxTreeParser.parse(url)
}

func createWorkingDirectory(in directory: String, fileManager: FileSystemManager = FileManager.default) -> String {
    let workingDirectory = "\(directory)/muter_tmp"
    try! fileManager.createDirectory(atPath: workingDirectory, withIntermediateDirectories: true, attributes: nil)
    return workingDirectory
}

func copySourceCode(fromFileAt sourcePath: String, to destinationPath: String) {
    let source = sourceCode(fromFileAt: sourcePath)
    try? source?.description.write(toFile: destinationPath, atomically: true, encoding: .utf8)
}

func sourceFilesContained(in path: String, excludingPathsIn blacklist: [String] = defaultBlacklist) -> [String] {
    let subpaths = FileManager.default.subpaths(atPath: path) ?? []
    return subpaths
        .filter { path in
            
            for item in blacklist where path.contains(item) {
                return false
            }
            
            return path.contains(".swift")
        }
        .map { path + "/" + $0 }
        .sorted()
}

func swapFilePaths(for discoveredFiles: [String], using workingDirectoryPath: String) ->  [String: String] {
    var swapFilePathsByOriginalPath: [String: String] = [:]
    
    for filePath in discoveredFiles {
        swapFilePathsByOriginalPath[filePath] = swapFilePath(forFileAt: filePath, using: workingDirectoryPath)
    }
    
    return swapFilePathsByOriginalPath
}

func swapFilePath(forFileAt path: String, using workingDirectory: String) -> String {
    guard let url = URL(string: path) else {
        return ""
    }
    return "\(workingDirectory)/\(url.lastPathComponent)"
}



