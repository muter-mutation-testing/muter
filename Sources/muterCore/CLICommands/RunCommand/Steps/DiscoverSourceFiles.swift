import Foundation
import Pathos

struct DiscoverSourceFiles: RunCommandStep {
    private let notificationCenter: NotificationCenter
    private let fileManager: FileSystemManager
    
    init(
        notificationCenter: NotificationCenter = .default,
        fileManager: FileSystemManager = FileManager.default
    ) {
        self.notificationCenter = notificationCenter
        self.fileManager = fileManager
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        notificationCenter.post(name: .sourceFileDiscoveryStarted, object: nil)
        
        let sourceFileCandidates = state.filesToMutate.isEmpty ?
            discoverSourceFiles(inDirectoryAt: state.tempDirectoryURL.path,
                                excludingPathsIn: state.muterConfiguration.excludeFileList,
                                ignoringFilesWithoutCoverage: state.filesWithoutCoverage) :
            findFilesToMutate(files: state.filesToMutate,
                              inDirectoryAt: state.tempDirectoryURL.path)
        
        let failure: MuterError = state.filesToMutate.isEmpty
            ? .noSourceFilesDiscovered
            : .noSourceFilesOnExclusiveList
        
        notificationCenter.post(name: .sourceFileDiscoveryFinished, object: sourceFileCandidates)

        return sourceFileCandidates.count >= 1 ?
            .success([.sourceFileCandidatesDiscovered(sourceFileCandidates)]) :
            .failure(failure)
    }
}

private extension DiscoverSourceFiles {
    private var defaultExcludeList: [FilePath] {
        return [
            ".build",
            "Build",
            "Carthage",
            "muter_tmp",
            "Pods",
            "Spec",
            "Test",
            "fastlane",
        ]
    }
    
    private func discoverSourceFiles(
        inDirectoryAt rootPath: FilePath,
        excludingPathsIn providedExcludeList: [FilePath],
        ignoringFilesWithoutCoverage filesWithoutCoverage: [FilePath]
    ) -> [FilePath] {
        let excludeList = providedExcludeList + defaultExcludeList
        let subpaths = fileManager.subpaths(atPath: rootPath) ?? []
        
        return includeSwiftFiles(
            from: subpaths
                .exclude(pathsContainingItems(from: excludeList, root: rootPath))
                .map { append(root: rootPath, to: $0) }
                .exclude(filesWithoutCoverageList(filesWithoutCoverage))
        )
    }

    private func pathsContainingItems(from excludeList: [FilePath], root: FilePath) -> (FilePath) -> Bool {
        let excludeAlso: [FilePath] = excludeList.flatMap { path in
            path.contains("*")
                ? expandGlobExpressions(root: root, pattern: path)
                : [path]
        }
        
        return { path in
            for item in excludeAlso where path.contains(item) { return true }
            return false
        }
    }
    
    private func filesWithoutCoverageList(_ list: [FilePath]) -> (FilePath) -> Bool {
        { path in list.contains(path) }
    }
    
    private func findFilesToMutate(
        files: [FilePath],
        inDirectoryAt path: FilePath
    ) -> [FilePath] {
        let glob = files
            .map { expandGlobExpressions(root: path, pattern: $0) }
            .flatMap { $0 }
        let list = files.map { append(root: path, to: $0) }
        let result = (glob + list).map(standardizing(path:))
        return includeSwiftFiles(from: result)
    }
    
    private func expandGlobExpressions(
        root: FilePath,
        pattern: FilePath
    ) -> [FilePath] {
        let path = Path(append(root: root, to: pattern))
        guard pattern.contains("*"), let paths = try? path.glob(),
              !paths.isEmpty else {
            return []
        }
        
        return paths.map(\.description)
    }
    
    private func append(root: FilePath, to path: FilePath) -> FilePath {
        return Path(root + "/" + path).normal.description
    }
    
    private func standardizing(path: String) -> String {
        let components = (path as NSString).pathComponents
        guard components.contains(".") || components.contains("..") else {
            return path
        }
        let result = URL(
                string: path,
                relativeTo: URL(fileURLWithPath: fileManager.currentDirectoryPath)
            )
            .map(\.absoluteString)
            .map(dropScheme)
            ?? path
        
        return result
    }
    
    private func includeSwiftFiles(from paths: [FilePath]) -> [FilePath] {
        return paths
            .include(swiftFiles)
            .include(fileManager.fileExists)
            .sorted()
    }

    private func swiftFiles(path: FilePath) -> Bool {
        return path.hasSuffix(".swift")
    }
    
    private func dropScheme(from path: FilePath) -> FilePath {
        return URLComponents(string: path)
            .map(\.scheme)
            .flatMap { $0 }
            .map { path.removingSubrange(path.range(of: "\($0)://")) }
            ?? path
    }
}
