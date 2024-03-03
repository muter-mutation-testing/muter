import Foundation

struct ProjectMappings: RunCommandStep {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter

    func run(with state: AnyRunCommandState) async throws -> [RunCommandState.Change] {
        notificationCenter.post(
            name: .mutationsDiscoveryFinished,
            object: state.mutationMapping
        )

        return []
    }
}
