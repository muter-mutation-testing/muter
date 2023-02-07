import Foundation

struct CopyProjectToTempDirectory: RunCommandStep {
    private let fileManager: FileSystemManager
    private let notificationCenter: NotificationCenter
    
    init(
        fileManager: FileSystemManager = FileManager.default,
        notificationCenter: NotificationCenter = .default
    ) {
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
    }
    
    func run(
        with state: AnyRunCommandState
    ) -> Result<[RunCommandState.Change], MuterError> {
        do {
            notificationCenter.post(
                name: .projectCopyStarted,
                object: nil
            )
                        
            try fileManager.copyItem(
                atPath: state.projectDirectoryURL.path,
                toPath: state.tempDirectoryURL.path
            )
            
            notificationCenter.post(
                name: .projectCopyFinished,
                object: state.tempDirectoryURL.path
            )
            
            return .success([
                .copyToTempDirectoryCompleted,
            ])
        } catch {
            return .failure(
                .projectCopyFailed(
                    reason: error.localizedDescription
                )
            )
        }
    }
}
