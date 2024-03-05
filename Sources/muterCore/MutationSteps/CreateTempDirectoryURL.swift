import Foundation

struct CreateMutatedProjectDirectoryURL: MutationStep {
    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        let destinationPath = destinationPath(
            with: state.projectDirectoryURL
        )

        return [
            .tempDirectoryUrlCreated(URL(fileURLWithPath: destinationPath))
        ]
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
