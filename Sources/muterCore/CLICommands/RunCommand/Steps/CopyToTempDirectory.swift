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
            let temporaryDirectory = try fileManager.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: state.projectDirectoryURL, // The appropriateFor parameter is used to make sure the temp directory is on the same volume as the passed parameter.
                create: true // the create parameter is ignored when passing .itemReplacementDirectory
            )
            
            notificationCenter.post(name: .projectCopyStarted, object: nil)
            
            let destinationPath = destinationDirectoryPath(in: temporaryDirectory, withProjectName: projectDirectory.lastPathComponent)
            try fileManager.copyItem(atPath: projectDirectory.path, toPath: destinationPath)
            
            notificationCenter.post(name: .projectCopyFinished, object: destinationPath)
            return .success([
                .tempDirectoryUrlCreated(URL(fileURLWithPath: destinationPath))
            ])
        } catch {
            return .failure(.projectCopyFailed(reason: error.localizedDescription))
        }
    }
    
    private func destinationDirectoryPath(in temporaryDirectory: URL, withProjectName name: String) -> String {
        let destination = temporaryDirectory.appendingPathComponent(name, isDirectory: true)
        return destination.path
    }
}
