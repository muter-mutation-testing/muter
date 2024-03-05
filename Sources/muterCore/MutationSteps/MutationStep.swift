import Foundation

protocol MutationStep {
    func run(with state: AnyMutationTestState) async throws -> [MutationTestState.Change]
}
