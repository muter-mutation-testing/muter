import Foundation

struct RemoveTempDirectory: RunCommandStep {
    private let fileManager: FileSystemManager
    private let notificationCenter: NotificationCenter = .default
    
    init(fileManager: FileSystemManager = FileManager.default) {
        self.fileManager = fileManager
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        do {
            notificationCenter.post(name: .removeTempDirectoryStarted, object: state.tempDirectoryURL.path)
            
            try fileManager.removeItem(atPath: state.tempDirectoryURL.path)
            
            notificationCenter.post(name: .removeTempDirectoryFinished, object: nil)
            return .success([
                .tempDirectoryRemoved,
            ])
        } catch {
            return .failure(.removeTempDirectoryFailed(reason: error.localizedDescription))
        }
    }
}

extension RemoveTempDirectory: RunCommandTrap {
    
    func run(with state: AnyRunCommandState) {
        try? fileManager.removeItem(atPath: state.tempDirectoryURL.path)
    }
}
