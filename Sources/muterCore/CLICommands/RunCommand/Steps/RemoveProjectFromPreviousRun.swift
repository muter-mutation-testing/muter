import Foundation

struct RemoveProjectFromPreviousRun: RunCommandStep {
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
        guard fileManager.fileExists(atPath: state.tempDirectoryURL.path) else {
            return .success([
                .removeProjectFromPreviousRunSkipped,
            ])
        }
        do {
            notificationCenter.post(name: .removeProjectFromPreviousRunStarted, object: nil)
            
            try fileManager.removeItem(atPath: state.tempDirectoryURL.path)
            
            notificationCenter.post(name: .removeProjectFromPreviousRunFinished, object: nil)
            
            return .success([
                .removeProjectFromPreviousRunCompleted,
            ])
        } catch {
            return .failure(.removeProjectFromPreviousRunFailed(reason: error.localizedDescription))
        }
    }
}
