import Foundation
import Pathos
import Curry

struct DiscoverSourceFiles: RunCommandStep {
    private let notificationCenter: NotificationCenter
    private let fileManager: FileSystemManager
    
    init(notificationCenter: NotificationCenter = .default,
         fileManager: FileSystemManager = FileManager.default) {
        self.notificationCenter = notificationCenter
        self.fileManager = fileManager
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        
        notificationCenter.post(name: .sourceFileDiscoveryStarted, object: nil)

        let path = state.dryRun ? state.projectDirectoryURL.path : state.tempDirectoryURL.path
        let sourceFileCandidates = state.filesToMutate.isEmpty ?
            discoverSourceFiles(inDirectoryAt: path,
                                excludingPathsIn: state.muterConfiguration.excludeList) :
            findFilesToMutate(files: state.filesToMutate,
                              inDirectoryAt: path)
        
        let failure = state.filesToMutate.isEmpty ?
            MuterError.noSourceFilesDiscovered :
            .noSourceFilesOnExclusiveList
        
        notificationCenter.post(name: .sourceFileDiscoveryFinished, object: sourceFileCandidates)

        return sourceFileCandidates.count >= 1 ?
            .success([.sourceFileCandidatesDiscovered(sourceFileCandidates)]) :
            .failure(failure)
    }
}

private extension DiscoverSourceFiles {
    var defaultExcludeList: [FilePath] {
        return [
            ".build",
            "Build",
            "Carthage",
            "muter_tmp",
            "Pods",
            "Spec",
            "Test",
            "fastlane"
        ]
    }
    
    func discoverSourceFiles(inDirectoryAt path: FilePath,
                             excludingPathsIn providedExcludeList: [FilePath] = []) -> [FilePath] {
        let excludeList = providedExcludeList + defaultExcludeList
        let subpaths = fileManager.subpaths(atPath: path) ?? []
        return includeSwiftFiles(
            from: subpaths
                .exclude(pathsContainingItems(from: excludeList))
                .map(curry(append)(path))
        )
    }
    
    func pathsContainingItems(from excludeList: [FilePath]) -> (FilePath) -> Bool {
        return { (path: FilePath) in
            
            for item in excludeList where path.contains(item) {
                return true
            }
            
            return false
        }
    }
    
    func findFilesToMutate(files: [FilePath],
                           inDirectoryAt path: FilePath) -> [FilePath] {
        let glob = files
            .map(curry(expandGlobExpressions)(path))
            .flatMap { $0 }
        let list = files.map(curry(append)(path))
        let result = (glob + list).map(standardizing(path:))
        return includeSwiftFiles(from: result)
    }
    
    func expandGlobExpressions(root: FilePath,
                               pattern: FilePath) -> [FilePath] {
        let path = append(root: root, to: pattern)
        guard pattern.contains("*"),
            let paths = try? glob(path),
            !paths.isEmpty else {
                return []
        }
        
        return paths
    }
    
    func append(root: FilePath, to path: FilePath) -> FilePath {
        return normalize(path: root + "/" + path)
    }
    
    func standardizing(path: String) -> String {
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
    
    func includeSwiftFiles(from paths: [FilePath]) -> [FilePath] {
        return paths
            .include(swiftFiles)
            .include(fileManager.fileExists)
            .sorted()
    }

    func swiftFiles(path: FilePath) -> Bool {
        return path.hasSuffix(".swift")
    }
    
    func dropScheme(from path: FilePath) -> FilePath {
        return URLComponents(string: path)
            .map(\.scheme)
            .flatMap { $0 }
            .map { path.removingSubrange(path.range(of: "\($0)://")) }
            ?? path
    }
}
