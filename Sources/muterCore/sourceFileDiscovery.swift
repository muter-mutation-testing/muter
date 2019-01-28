import Foundation

private let defaultExcludeList = [
    ".build",
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
        .exclude(pathsContainingItems(from: excludeList))
        .include(swiftFiles)
        .map { path + "/" + $0 }
        .sorted()
}

private func pathsContainingItems(from excludeList: [String]) -> (String) -> Bool {
    return { (path: String) in

        for item in excludeList where path.contains(item) {
            return true
        }

        return false
    }
}

private func swiftFiles(path: String) -> Bool {
    return path.hasSuffix(".swift")
}
