import Foundation

struct GenerateSwapFilePaths: RunCommandStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        let result = createSwapFileDirectory(in: state.tempDirectoryURL.path)
        
        switch result {
        case .success(let swapFileDirectoryPath):
            
            let filePaths = state.sourceCodeByFilePath.keys.map { String($0) }
            let swapFilePathsByOriginalPath = swapFilePaths(
                forFilesAt: filePaths,
                using: swapFileDirectoryPath
            )
            
            return .success([.swapFilePathGenerated(swapFilePathsByOriginalPath)])
            
        case .failure(let error):
            return .failure(.unableToCreateSwapFileDirectory(reason: error.localizedDescription))
        }
    }
}

private extension GenerateSwapFilePaths {
    func createSwapFileDirectory(in directory: FilePath) -> Result<FilePath, Error> {
        do {
            let swapFileDirectory = "\(directory)/muter_tmp"
            try fileManager.createDirectory(atPath: swapFileDirectory,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
            return .success(swapFileDirectory)
        } catch {
            return .failure(error)
        }
    }
}

internal extension GenerateSwapFilePaths { // this is internal to simplify testing
    
    func swapFilePaths(forFilesAt paths: [FilePath],
                       using workingDirectoryPath: FilePath) ->  [FilePath: FilePath] {
        var swapFilePathsByOriginalPath: [FilePath: FilePath] = [:]
        
        for path in paths {
            swapFilePathsByOriginalPath[path] = swapFilePath(forFileAt: path, using: workingDirectoryPath)
        }
        
        return swapFilePathsByOriginalPath
    }
    
    func swapFilePath(forFileAt path: FilePath, using workingDirectory: FilePath) -> String {
        let url = URL(fileURLWithPath: path)
        return "\(workingDirectory)/\(url.lastPathComponent)"
    }
}
