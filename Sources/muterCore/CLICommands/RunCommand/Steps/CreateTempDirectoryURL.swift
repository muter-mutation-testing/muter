import Foundation

struct CreateTempDirectoryURL: RunCommandStep {
    private let notificationCenter: NotificationCenter
    
    init(
        notificationCenter: NotificationCenter = .default
    ) {
        self.notificationCenter = notificationCenter
    }
    
    func run(
        with state: AnyRunCommandState
    ) -> Result<[RunCommandState.Change], MuterError> {
        notificationCenter.post(
            name: .tempDirectoryCreationStarted,
            object: nil
        )
        
        let destinationPath = destinationPath(
            with: state.projectDirectoryURL
        )
        
        notificationCenter.post(
            name: .tempDirectoryCreationFinished,
            object: nil
        )
        
        return .success([
            .tempDirectoryUrlCreated(URL(fileURLWithPath: destinationPath)),
        ])
    }

    private func destinationPath(
        with projectDirectoryURL: URL
    ) -> String {
        let lastComponent = projectDirectoryURL.lastPathComponent
        let modifiedDirectory = projectDirectoryURL.deletingLastPathComponent()
        let destination = modifiedDirectory.appendingPathComponent(lastComponent + "_mutated")
        return destination.path
    }
}
