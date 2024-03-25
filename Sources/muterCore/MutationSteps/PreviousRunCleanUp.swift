import Foundation

struct PreviousRunCleanUp: MutationStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        guard fileManager.fileExists(
            atPath: state.mutatedProjectDirectoryURL.path
        )
        else {
            return []
        }

        do {
            try fileManager.removeItem(
                atPath: state.mutatedProjectDirectoryURL.path
            )
            return []
        } catch {
            throw MuterError.removeProjectFromPreviousRunFailed(
                reason: error.localizedDescription
            )
        }
    }
}
