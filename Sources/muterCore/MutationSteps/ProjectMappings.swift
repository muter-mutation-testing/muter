import Foundation

struct ProjectMappings: MutationStep {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter

    func run(with state: AnyMutationTestState) async throws -> [MutationTestState.Change] {
        notificationCenter.post(
            name: .mutationsDiscoveryFinished,
            object: state.mutationMapping
        )

        return []
    }
}
