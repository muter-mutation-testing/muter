import Foundation
import Pathos
import Curry

struct DiscoverSourceFiles: RunCommandStep {
    private let notificationCenter: NotificationCenter = .default
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        
        notificationCenter.post(name: .sourceFileDiscoveryStarted, object: nil)
        
        let sourceFileCandidates = state.filesToMutate.isEmpty ?
            discoverSourceFiles(inDirectoryAt: state.tempDirectoryURL.path,
                                excludingPathsIn: state.muterConfiguration.excludeList) :
            findFilesToMutate(files: state.filesToMutate,
                              inDirectoryAt: state.tempDirectoryURL.path)
        
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
    var defaultExcludeList: [String] {
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
    
    func discoverSourceFiles(inDirectoryAt path: String,
                             excludingPathsIn providedExcludeList: [String] = []) -> [FilePath] {
        let excludeList = providedExcludeList + defaultExcludeList
        let subpaths = FileManager.default.subpaths(atPath: path) ?? []
        return includeSwiftFiles(
            from: subpaths
                .exclude(pathsContainingItems(from: excludeList))
                .map(curry(append)(path))
        )
    }
    
    func pathsContainingItems(from excludeList: [String]) -> (String) -> Bool {
        return { (path: String) in
            
            for item in excludeList where path.contains(item) {
                return true
            }
            
            return false
        }
    }
    
    func findFilesToMutate(files: [String],
                           inDirectoryAt path: String) -> [FilePath] {
        let glob = files.map(curry(expandGlobExpressions)(path)).flatMap { $0 }
        let list = files.map(curry(append)(path))
        return includeSwiftFiles(from: glob + list)
    }
    
    func expandGlobExpressions(root: String, pattern: String) -> [String] {
        let globPath = normalize(path: root + "/" + pattern)
        guard pattern.contains("*"),
            let paths = try? glob(globPath),
            !paths.isEmpty else {
                return [pattern]
        }
        
        return paths
    }
    
    func append(root: String, to path: String) -> String {
        return normalize(path: root + "/" + path)
    }
    
    func includeSwiftFiles(from paths: [FilePath]) -> [FilePath] {
        return paths
            .include(swiftFiles)
            .include(FileManager.default.fileExists)
            .sorted()
    }

    func swiftFiles(path: String) -> Bool {
        return path.hasSuffix(".swift")
    }
}
