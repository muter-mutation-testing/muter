import Foundation

struct CreateTempDirectoryURL: RunCommandStep {
    private let fileManager: FileSystemManager
    private let notificationCenter: NotificationCenter
    
    init(
        fileManager: FileSystemManager = FileManager.default,
        notificationCenter: NotificationCenter = .default
    ) {
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        do {
            notificationCenter.post(name: .tempDirectoryCreationStarted, object: nil)
            
            let destinationPath = try destinationPath(with: state)
            
            notificationCenter.post(name: .tempDirectoryCreationFinished, object: nil)
            
            return .success([
                .tempDirectoryUrlCreated(URL(fileURLWithPath: destinationPath)),
            ])
        } catch {
            return .failure(.createTempDirectoryUrlFailed(reason: error.localizedDescription))
        }
    }
}

private extension CreateTempDirectoryURL {
    
    private func destinationPath(with state: AnyRunCommandState) throws -> String {
        if state.muterConfiguration.mutateFilesInSiblingOfProjectFolder {
            return destinationPathToSiblingProjectFolder(with: state.projectDirectoryURL)
        } else {
            return try destinationPathToTempFolder(with: state.projectDirectoryURL)
        }
    }
    
    private func destinationPathToTempFolder(with projectDirectoryURL: URL) throws -> String {
        let temporaryDirectory = try fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: projectDirectoryURL, // The appropriateFor parameter is used to make sure the temp directory is on the same volume as the passed parameter.
            create: true // the create parameter is ignored when passing .itemReplacementDirectory
        )
        let destination = temporaryDirectory.appendingPathComponent(projectDirectoryURL.lastPathComponent, isDirectory: true)
        return destination.path
    }
    
    private func destinationPathToSiblingProjectFolder(with projectDirectoryURL: URL) -> String {
        let lastComponent = projectDirectoryURL.lastPathComponent
        let modifiedDirectory = projectDirectoryURL.deletingLastPathComponent()
        let destination = modifiedDirectory.appendingPathComponent(lastComponent + "_mutated")
        return destination.path
    }
}
