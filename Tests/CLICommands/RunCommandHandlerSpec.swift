import Quick
import Nimble
import Foundation
@testable import muterCore

@available(OSX 10.13, *)
class RunCommandHandlerSpec: QuickSpec {
    override func spec() {
        
        var stepSpy1: RunCommandStepSpy!
        var stepSpy2: RunCommandStepSpy!
        var stepSpy3: RunCommandStepSpy!
        
        var expectedState: RunCommandState!
        
        var runCommandHandler: RunCommandHandler!

        describe("RunCommandHandler") {
            var runCommandResult: Error?
            
            context("when there are no failures in any of it steps") {
                beforeEach {
                    stepSpy1 = RunCommandStepSpy()
                    stepSpy1.resultToReturn = .success([.tempDirectoryUrlCreated(URL(string: "/lol/son")!)])
                    
                    stepSpy2 = RunCommandStepSpy()
                    stepSpy2.resultToReturn = .success([.projectDirectoryUrlDiscovered(URL(string: "/lol")!)])
                    
                    stepSpy3 = RunCommandStepSpy()
                    stepSpy3.resultToReturn = .success([])
                    
                    expectedState = RunCommandState()
                    
                    runCommandHandler = RunCommandHandler(steps: [stepSpy1,
                                                                  stepSpy2,
                                                                  stepSpy3],
                                                          state: expectedState)

                    do {
                        try runCommandHandler.run()
                    }
                    catch {
                        runCommandResult = error
                    }
                }
                
                it("runs all its steps") {
                    expect(stepSpy1.methodCalls) == ["run(with:)"]
                    expect(stepSpy2.methodCalls) == ["run(with:)"]
                    expect(stepSpy3.methodCalls) == ["run(with:)"]
                }
                
                it("shares the same state across all of the steps") {
                    expect(stepSpy1.states.first) === expectedState
                    expect(stepSpy2.states.first) === expectedState
                    expect(stepSpy3.states.first) === expectedState
                }
                
                it("applies any state mutations returned by the steps") {
                    expect(expectedState.tempDirectoryURL) == URL(string: "/lol/son")!
                    expect(expectedState.projectDirectoryURL) == URL(string: "/lol")!
                }
                
                it("returns success") {
                    if let runCommandResult = runCommandResult {
                        fail("expected success but got \(runCommandResult)")
                        return
                    }
                }
                
            }
            
            context("when there is a failure in one of its steps") {
                beforeEach {
                    stepSpy1 = RunCommandStepSpy()
                    stepSpy1.resultToReturn = .success([])
                    
                    stepSpy2 = RunCommandStepSpy()
                    stepSpy2.resultToReturn = .failure(.configurationParsingError(reason: ""))
                    
                    stepSpy3 = RunCommandStepSpy()
                    stepSpy3.resultToReturn = .success([])
                    
                    expectedState = RunCommandState()
                    
                    runCommandHandler = RunCommandHandler(steps: [stepSpy1,
                                                                  stepSpy2,
                                                                  stepSpy3],
                                                          state: expectedState)

                    do {
                        try runCommandHandler.run()
                    }
                    catch {
                        runCommandResult = error
                    }
                }
                
                it("won't run any subsequent steps after the failing step") {
                    expect(stepSpy1.methodCalls) == ["run(with:)"]
                    expect(stepSpy2.methodCalls) == ["run(with:)"]
                    expect(stepSpy3.methodCalls).to(beEmpty())
                }
                
                it("won't share the state with any subsequent steps after the failing step") {
                    expect(stepSpy1.states.first) === expectedState
                    expect(stepSpy2.states.first) === expectedState
                    expect(stepSpy3.states).to(beEmpty())
                }
                
                it("cascades up the failure from the failing step") {
                    guard case .configurationParsingError = runCommandResult as? MuterError else {
                        fail("expected a configuration failure but got \(String(describing: runCommandResult))")
                        return
                    }
                }
            }
            
        }
    }
}

