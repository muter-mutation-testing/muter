import Foundation

struct CopyProjectToTempDirectory: RunCommandStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter

    func run(
        with state: AnyRunCommandState
    ) async throws -> [RunCommandState.Change] {
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

            return [.copyToTempDirectoryCompleted]
        } catch {
            throw MuterError.projectCopyFailed(
                    reason: error.localizedDescription
                )
        }
    }
}
