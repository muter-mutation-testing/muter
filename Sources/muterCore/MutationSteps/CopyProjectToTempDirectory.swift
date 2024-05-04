import Foundation

class CopyProjectToTempDirectory: MutationStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        do {
            notificationCenter.post(
                name: .projectCopyStarted,
                object: nil
            )

            try fileManager.copyItem(
                atPath: state.projectDirectoryURL.path,
                toPath: state.mutatedProjectDirectoryURL.path
            )

            let copiedBuildDirectory: String
            if #available(macOS 13.0, *) {
                copiedBuildDirectory = state.mutatedProjectDirectoryURL.appending(path: state.muterConfiguration.buildPath).path
            } else {
                copiedBuildDirectory = state.mutatedProjectDirectoryURL.appendingPathComponent(state.muterConfiguration.buildPath).path
            }
            // ensure that we don't have any dirty build state before running tests in copied directory
            if fileManager.fileExists(atPath: copiedBuildDirectory) {
                try fileManager.removeItem(atPath: copiedBuildDirectory)
            }

            notificationCenter.post(
                name: .projectCopyFinished,
                object: state.mutatedProjectDirectoryURL.path
            )

            return []
        } catch {
            throw MuterError.projectCopyFailed(
                reason: error.localizedDescription
            )
        }
    }
}
