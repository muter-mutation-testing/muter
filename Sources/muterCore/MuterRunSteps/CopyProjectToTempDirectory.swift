import Foundation

class CopyProjectToTempDirectory: RunCommandStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    private lazy var fileManagerDelegate = CopyFileManagerDelegate()

    func run(
        with state: AnyRunCommandState
    ) async throws -> [RunCommandState.Change] {
        let previousDelegate = fileManager.delegate
        fileManager.delegate = fileManagerDelegate

        defer {
            fileManager.delegate = previousDelegate
        }

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

            return []
        } catch {
            throw MuterError.projectCopyFailed(
                reason: error.localizedDescription
            )
        }
    }
}

private class CopyFileManagerDelegate: NSObject, FileManagerDelegate {
    func fileManager(
        _ fileManager: FileManager,
        shouldCopyItemAtPath srcPath: String,
        toPath dstPath: String
    ) -> Bool {
        true
    }
}
