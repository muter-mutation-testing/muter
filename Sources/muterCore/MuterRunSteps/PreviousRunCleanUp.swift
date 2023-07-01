import Foundation

struct PreviousRunCleanUp: RunCommandStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager

    func run(
        with state: AnyRunCommandState
    ) -> Result<[RunCommandState.Change], MuterError> {
        guard fileManager.fileExists(
            atPath: state.tempDirectoryURL.path
        )
        else {
            return .success([])
        }

        do {
            try fileManager.removeItem(
                atPath: state.tempDirectoryURL.path
            )
            return .success([])
        } catch {
            return .failure(
                .removeProjectFromPreviousRunFailed(
                    reason: error.localizedDescription
                )
            )
        }
    }
}
