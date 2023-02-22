import Foundation

struct CreateTempDirectoryURL: RunCommandStep {
    func run(
        with state: AnyRunCommandState
    ) -> Result<[RunCommandState.Change], MuterError> {
        let destinationPath = destinationPath(
            with: state.projectDirectoryURL
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
