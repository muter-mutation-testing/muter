import Foundation

final class DiscoverProjectCoverage: RunCommandStep {
    private let makeProcess: () -> Launchable
    
    private let notificationCenter: NotificationCenter
    
    init(
        process: @autoclosure @escaping () -> Launchable = Process(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.makeProcess = process
        self.notificationCenter = notificationCenter
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {        
        guard let runner = runner(for: state.muterConfiguration.testCommandExecutable) else {
            return .success([
                .projectCoverage(.null),
            ])
        }

        notificationCenter.post(name: .projectCoverageDiscoveryStarted, object: nil)

        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(state.tempDirectoryURL.path)

        defer {
            FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath)
        }

        switch runner.run(process: makeProcess, with: state.muterConfiguration) {
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
