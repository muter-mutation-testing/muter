@testable import muterCore

class RunCommandStepSpy: Spy, RunCommandStep {
    private(set) var methodCalls: [String] = []
    private(set) var states: [AnyRunCommandState] = []
    var resultToReturn: Result<[RunCommandState.Change], MuterError>!

    func run(with state: AnyRunCommandState) async throws -> [RunCommandState.Change] {
        methodCalls.append(#function)
        states.append(state)
        
        switch resultToReturn {
        case .success(let result):
            return result
        case .failure(let failure):
            throw failure
        case .none:
            throw MuterError.literal(reason: #function)
        }
    }
}
