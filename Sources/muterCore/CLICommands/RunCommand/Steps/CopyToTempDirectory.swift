import Foundation

struct CopyProjectToTempDirectory: RunCommandStep {
    private let fileManager: FileSystemManager
    private let notificationCenter: NotificationCenter = .default
    
    init(fileManager: FileSystemManager = FileManager.default) {
        self.fileManager = fileManager
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        do {
            let projectDirectory = state.projectDirectoryURL
            notificationCenter.post(name: .projectCopyStarted, object: nil)
            
            let destinationPath = destinationDirectoryPath(in: projectDirectory, withSuffix: "_mutated")
            try fileManager.copyItem(atPath: projectDirectory.path, toPath: destinationPath)
            
            notificationCenter.post(name: .projectCopyFinished, object: destinationPath)
            return .success([
                .tempDirectoryUrlCreated(URL(fileURLWithPath: destinationPath)),
            ])
        } catch {
            return .failure(.projectCopyFailed(reason: error.localizedDescription))
        }
    }
    
    private func destinationDirectoryPath(in directory: URL, withSuffix name: String) -> String {
        let lastComponent = directory.lastPathComponent
        let modifiedDirectory = directory.deletingLastPathComponent()
        let destination = modifiedDirectory.appendingPathComponent(lastComponent + name)
        return destination.path
    }
}
