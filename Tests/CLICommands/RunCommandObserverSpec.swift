import Quick
import Nimble
import Foundation
@testable import muterCore
class RunCommandObserverSpec: QuickSpec {
    override func spec() {
        describe("RunCommandObserverSpec") {
            describe("\(RunCommandObserver.handleNewMutationTestOutcomeAvailable)") {
                
                var reporterWasCalled: Bool!
                let reporterSpy: ([MutationTestOutcome]) -> String = { _ in
                    reporterWasCalled = true
                    return ""
                }
                
                let notification = Notification(
                    name: .newMutationTestOutcomeAvailable,
                    object: (
                        outcome: MutationTestOutcome(testSuiteOutcome: .failed,
                                                     appliedMutation: .negateConditionals,
                                                     filePath: "some/path",
                                                     position: .firstPosition,
                                                     operatorDescription: "some description"),
                        remainingOperatorsCount: 0
                    ),
                    userInfo: nil
                )
                
                beforeEach {
                    reporterWasCalled = false
                }
                
                it("calls its reporter when it shouldn't log") {
                    let subject = RunCommandObserver(reporter: reporterSpy, shouldLog: false)
                    subject.handleNewMutationTestOutcomeAvailable(notification: notification)
                    
                    expect(reporterWasCalled) == true
                }
                
                it("doesn't call its reporter when it should log") {
                    let subject = RunCommandObserver(reporter: reporterSpy, shouldLog: true)
                    subject.handleNewMutationTestOutcomeAvailable(notification: notification)
                    
                    expect(reporterWasCalled) == false
                }
            }
        }
    }
}

