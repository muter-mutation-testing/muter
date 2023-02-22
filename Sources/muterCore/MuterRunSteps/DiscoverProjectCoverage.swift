import Foundation

final class DiscoverProjectCoverage: RunCommandStep {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.projectCoverage)
    private var projectCoverage: ProjectCoverage

    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        guard let coverage = projectCoverage(
            state.muterConfiguration.buildSystem
        ) else {
            return .success([
                .projectCoverage(.null),
            ])
        }

        notificationCenter.post(
            name: .projectCoverageDiscoveryStarted,
            object: nil
        )

        let currentDirectoryPath = fileManager.currentDirectoryPath
        fileManager.changeCurrentDirectoryPath(state.tempDirectoryURL.path)

        defer {
            fileManager.changeCurrentDirectoryPath(currentDirectoryPath)
        }

        switch coverage.run(with: state.muterConfiguration) {
        case .success(let coverage):
            notificationCenter.post(
                name: .projectCoverageDiscoveryFinished,
                object: true
            )

            return .success([.projectCoverage(coverage)])
        case .failure:
            notificationCenter.post(
                name: .projectCoverageDiscoveryFinished,
                object: false
            )
            
            return .success([.projectCoverage(.null)])
        }
    }
}
