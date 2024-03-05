@testable import muterCore

class MutationStepSpy: Spy, MutationStep {
    private(set) var methodCalls: [String] = []
    private(set) var states: [AnyMutationTestState] = []
    var resultToReturn: Result<[MutationTestState.Change], MuterError>!

    func run(with state: AnyMutationTestState) async throws -> [MutationTestState.Change] {
        methodCalls.append(#function)
        states.append(state)

        switch resultToReturn {
        case let .success(result):
            return result
        case let .failure(failure):
            throw failure
        case .none:
            throw MuterError.literal(reason: #function)
        }
    }
}
