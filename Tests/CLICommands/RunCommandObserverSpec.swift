import Quick
import Nimble
import Foundation
@testable import muterCore

class RunCommandObserverSpec: QuickSpec {
    override func spec() {
        describe("RunCommandObserver") {
            describe("handleNewMutationTestOutcomeAvailable") {
                
                var flushHandlerWasCalled: Bool!
                let flushHandlerSpy: () -> Void = {
                    flushHandlerWasCalled = true
                }
                
                var notification: Notification!
                
                beforeEach {
                    flushHandlerWasCalled = false
                    notification = Notification(
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
                }
                
                it("flushes stdout when using an Xcode reporter") {
                    let subject = RunCommandObserver(reporter: .xcode, flushHandler: flushHandlerSpy)
                    subject.handleNewMutationTestOutcomeAvailable(notification: notification)
                    expect(flushHandlerWasCalled) == true
                }
                
                it("doesn't flush stdout when using a JSON reporter") {
                    let subject = RunCommandObserver(reporter: .json, flushHandler: flushHandlerSpy)
                    subject.handleNewMutationTestOutcomeAvailable(notification: notification)
                    expect(flushHandlerWasCalled) == false
                }
                
                it("doesn't flush stdout when using a plain text reporter") {
                    let subject = RunCommandObserver(reporter: .plainText, flushHandler: flushHandlerSpy)
                    subject.handleNewMutationTestOutcomeAvailable(notification: notification)
                    expect(flushHandlerWasCalled) == false
                }
            }
        }
    }
}

