import Quick
import Nimble
import Foundation
import SwiftSyntax
@testable import muterCore

class RunCommandObserverSpec: QuickSpec {
    override func spec() {
        describe("RunCommandObserver") {
            let fileManagerSpy = FileManagerSpy()
            fileManagerSpy.currentDirectoryPathToReturn = "/"
            
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
                        object: MutationTestOutcome.Mutation.make(
                            testSuiteOutcome: .passed,
                            point: .make(
                                mutationOperatorId: .ror,
                                filePath: "some/path",
                                position: .firstPosition
                            ),
                            snapshot: .null),
                        userInfo: nil
                    )
                }
                
                it("flushes stdout when using an Xcode reporter") {
                    let subject = RunCommandObserver(
                        options: .make(reportFormat: .xcode),
                        fileManager: fileManagerSpy,
                        flushHandler: flushHandlerSpy
                    )

                    subject.handleNewMutationTestOutcomeAvailable(notification: notification)
                    expect(flushHandlerWasCalled) == true
                }
                
                it("doesn't flush stdout when using a JSON reporter") {
                    let subject = RunCommandObserver(
                        options: .make(reportFormat: .json),
                        fileManager: fileManagerSpy,
                        flushHandler: flushHandlerSpy
                    )

                    subject.handleNewMutationTestOutcomeAvailable(notification: notification)
                    expect(flushHandlerWasCalled) == false
                }
                
                it("doesn't flush stdout when using a plain text reporter") {
                    let subject = RunCommandObserver(
                        options: .make(reportFormat: .plain),
                        fileManager: fileManagerSpy,
                        flushHandler: flushHandlerSpy
                    )

                    subject.handleNewMutationTestOutcomeAvailable(notification: notification)
                    expect(flushHandlerWasCalled) == false
                }
            }
            
            describe("logFileName(from:)") {
                it("names a log file as baseline run.log when there is no MutationPoint") {
                    let subject = RunCommandObserver(
                        options: .make(reportFormat: .plain),
                        fileManager: fileManagerSpy,
                        flushHandler: {}
                    )

                    expect(subject.logFileName(from: nil)) == "baseline run.log"
                }
                
                it("names a log file using the mutation point when it's provided") {

                    let mutationPoint1 = MutationPoint(mutationOperatorId: .ror,
                                                              filePath: "~/user/file.swift",
                                                              position: .firstPosition)
                    let mutationPoint2 = MutationPoint(mutationOperatorId: .removeSideEffects,
                                                       filePath: "~/user/file2.swift",
                                                       position: MutationPosition(utf8Offset: 2, line: 5, column: 6))
                    
                    let subject = RunCommandObserver(
                        options: .make(reportFormat: .xcode),
                        fileManager: fileManagerSpy,
                        flushHandler: {}
                    )
                    
                    expect(subject.logFileName(from: mutationPoint1)) == "RelationalOperatorReplacement @ file.swift-0-0.log"
                    expect(subject.logFileName(from: mutationPoint2)) == "RemoveSideEffects @ file2.swift-5-6.log"
                }
            }
        }
    }
}
