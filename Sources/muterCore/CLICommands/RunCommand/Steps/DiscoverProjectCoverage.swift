import Foundation

final class DiscoverProjectCoverage: RunCommandStep {
    private let makeProcess: ProcessFactory
    
    private let notificationCenter: NotificationCenter
    
    init(
        process: @autoclosure @escaping ProcessFactory = Process(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.makeProcess = process
        self.notificationCenter = notificationCenter
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {        
        guard let coverage = buildSystemCoverge(
            for: state.muterConfiguration.buildSystem,
            processFactory: makeProcess
        ) else {
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

        switch coverage.run(process: makeProcess, with: state.muterConfiguration) {
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

    func buildSystemCoverge(
        for buildSystem: BuildSystem,
        processFactory: @escaping ProcessFactory
    ) -> BuildSystemCoverage? {
        switch buildSystem {
        case .swift: return SwiftCoverage(processFactory)
        case .xcodebuild: return XcodeCoverage(processFactory)
        default: return nil
        }
    }
}
