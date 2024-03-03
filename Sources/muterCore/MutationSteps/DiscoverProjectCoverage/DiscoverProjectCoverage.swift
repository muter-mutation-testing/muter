import Foundation

final class DiscoverProjectCoverage: RunCommandStep {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.projectCoverage)
    private var projectCoverage: ProjectCoverage

    func run(
        with state: AnyRunCommandState
    ) async throws -> [RunCommandState.Change] {
        guard let coverage = projectCoverage(
            state.muterConfiguration.buildSystem
        )
        else {
            return [.projectCoverage(.null)]
        }

        notificationCenter.post(
            name: .projectCoverageDiscoveryStarted,
            object: nil
        )

        let currentDirectoryPath = fileManager.currentDirectoryPath
        fileManager.changeCurrentDirectoryPath(state.mutatedProjectDirectoryURL.path)

        defer {
            fileManager.changeCurrentDirectoryPath(currentDirectoryPath)
        }

        switch coverage.run(with: state.muterConfiguration) {
        case let .success(coverage):
            notificationCenter.post(
                name: .projectCoverageDiscoveryFinished,
                object: true
            )

            return [.projectCoverage(coverage)]
        case .failure:
            notificationCenter.post(
                name: .projectCoverageDiscoveryFinished,
                object: false
            )

            return [.projectCoverage(.null)]
        }
    }
}
