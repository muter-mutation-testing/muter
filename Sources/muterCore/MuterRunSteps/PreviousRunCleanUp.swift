import Foundation

struct PreviousRunCleanUp: RunCommandStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager

    func run(
        with state: AnyRunCommandState
    ) async throws -> [RunCommandState.Change] {
        guard fileManager.fileExists(
            atPath: state.tempDirectoryURL.path
        )
        else {
            return []
        }

        do {
            try fileManager.removeItem(
                atPath: state.tempDirectoryURL.path
            )
            return []
        } catch {
            throw MuterError.removeProjectFromPreviousRunFailed(
                    reason: error.localizedDescription
            )
        }
    }
}
