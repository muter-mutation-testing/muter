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

private let defaultExcludeList = [
    ".build",
    ".framework",
    ".swiftdep",
    ".swiftmodule",
    "Build",
    "Carthage",
    "muter_tmp",
    "Pods",
    "Spec",
    "Test",
]

func discoverSourceFiles(inDirectoryAt path: String, excludingPathsIn providedExcludeList: [String] = []) -> [String] {
    let excludeList = providedExcludeList + defaultExcludeList
    let subpaths = FileManager.default.subpaths(atPath: path) ?? []
    return subpaths
        .filter { path in

            for item in excludeList where path.contains(item) {
                return false
            }

            return path.contains(".swift")
        }
        .map { path + "/" + $0 }
        .sorted()
}

// MARK - Working Directory
func createWorkingDirectory(in directory: String, fileManager: FileSystemManager = FileManager.default) -> String {
    let workingDirectory = "\(directory)/muter_tmp"
    try! fileManager.createDirectory(atPath: workingDirectory, withIntermediateDirectories: true, attributes: nil)
    return workingDirectory
}

func removeWorkingDirectory(at path: String) {
    do {
        try FileManager.default.removeItem(atPath: path)
    } catch {
        printMessage("Encountered error removing Muter's working directory")
        printMessage("\(error)")
    }
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
    guard let url = URL(string: path) else {
        return ""
    }
    return "\(workingDirectory)/\(url.lastPathComponent)"
}
