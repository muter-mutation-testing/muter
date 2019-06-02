@testable import muterCore

class RunCommandStepSpy: Spy, RunCommandStep {
    private(set) var methodCalls: [String] = []
    private(set) var states: [AnyRunCommandState] = []
    var resultToReturn: Result<[RunCommandState.Change], MuterError>!
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        methodCalls.append(#function)
        states.append(state)
        return resultToReturn
    }
}
