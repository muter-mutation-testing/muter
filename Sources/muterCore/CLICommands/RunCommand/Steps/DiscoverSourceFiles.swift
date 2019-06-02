import Foundation

struct DiscoverSourceFiles: RunCommandStep {
    private let notificationCenter: NotificationCenter = .default
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        
        notificationCenter.post(name: .sourceFileDiscoveryStarted, object: state.tempDirectoryURL)
        
        let sourceFileCandidates = discoverSourceFiles(inDirectoryAt: state.tempDirectoryURL.path,
                                                         excludingPathsIn: state.muterConfiguration.excludeList)
        
        notificationCenter.post(name: .sourceFileDiscoveryFinished, object: sourceFileCandidates)

        return sourceFileCandidates.count >= 1 ?
            .success([.sourceFileCandidatesDiscovered(sourceFileCandidates)]) :
            .failure(.noSourceFilesDiscovered)
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
                             excludingPathsIn providedExcludeList: [String] = []) -> [String] {
        let excludeList = providedExcludeList + defaultExcludeList
        let subpaths = FileManager.default.subpaths(atPath: path) ?? []
        return subpaths
            .exclude(pathsContainingItems(from: excludeList))
            .include(swiftFiles)
            .map { path + "/" + $0 }
            .sorted()
    }
    
    func pathsContainingItems(from excludeList: [String]) -> (String) -> Bool {
        return { (path: String) in
            
            for item in excludeList where path.contains(item) {
                return true
            }
            
            return false
        }
    }
    
    func swiftFiles(path: String) -> Bool {
        return path.hasSuffix(".swift")
    }
}
