@testable import muterCore
import Foundation
import SwiftSyntax
import Quick
import Nimble

class MutationTestingSpec: QuickSpec {
    override func spec() {
        
        var delegateSpy: MutationTestingDelegateSpy!
        var mutationOperatorStub: MutationOperator!
        
        describe("performMutationTesting") {
            beforeEach {
                delegateSpy = MutationTestingDelegateSpy()
                mutationOperatorStub = MutationOperator(mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "a file path", position: .firstPosition),
                                                        source: SyntaxFactory.makeReturnKeyword())
            }
            
            context("when the baseline test run passes") {
                
                beforeEach {
                    delegateSpy.testSuiteOutcomes = [.passed, .failed, .failed]
                }
                
                it("performs a mutation test for every mutation operator") {
                    let expectedTestOutcomes = [
                        MutationTestOutcome(testSuiteOutcome: .failed,
                                            mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "a file path", position: .firstPosition),
                                            operatorDescription: ""),
                        MutationTestOutcome(testSuiteOutcome: .failed,
                                            mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "a file path", position: .firstPosition),
                                            operatorDescription: ""),
                    ]
                    
                    let actualTestOutcomes = performMutationTesting(using: [mutationOperatorStub, mutationOperatorStub], delegate: delegateSpy)
                    
                    expect(delegateSpy.methodCalls).to(equal([
                        // Base test suite run
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        // First operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)",
                        // Second operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)"
                        ]))
                    
                    expect(delegateSpy.backedUpFilePaths.count).to(equal(2))
                    expect(delegateSpy.restoredFilePaths.count).to(equal(2))
                    expect(delegateSpy.backedUpFilePaths).to(equal(delegateSpy.restoredFilePaths))
                    
                    expect(delegateSpy.mutatedFileContents.first).to(equal(SyntaxFactory.makeReturnKeyword().description))
                    expect(delegateSpy.mutatedFilePaths.first).to(equal("a file path"))
                    
                    expect(actualTestOutcomes).to(equal(expectedTestOutcomes))
                }
                
                it("generates logs for every mutation operator") {
                    let notificationSpy = NotificationCenterSpy()
                    let _ = performMutationTesting(
                        using: [
                            MutationOperator(
                                mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/some/file/path/first.swift", position: .firstPosition),
                                
                                source: SyntaxFactory.makeReturnKeyword()),
                            MutationOperator(
                                mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/some/file/path/second.swift", position: .firstPosition),
                                
                                source: SyntaxFactory.makeReturnKeyword())
                        ],
                        delegate: delegateSpy,
                        notificationCenter: notificationSpy
                    )
                    
                    expect(notificationSpy.methodCalls).to(equal([
                        "post(name:object:userInfo:)",
                        "post(name:object:userInfo:)",
                        "post(name:object:userInfo:)",
                        "post(name:object:userInfo:)"
                    ]))
                    
                    let logs = notificationSpy.payloads
                        .filter { $0.name == .newTestLogAvailable }
                        .map { $0.object as? (fileName: String, log: String) }
                    
                    expect(logs.count).to(equal(2))
                    
                    expect(logs[0]?.fileName).to(equal("first"))
                    expect(logs[0]?.log).to(equal("testLog"))
                    
                    expect(logs[1]?.fileName).to(equal("second"))
                    expect(logs[1]?.log).to(equal("testLog"))
                }
            }
            
            context("when the baseline test run doesn't pass") {
                context("due to a failing test") {
                    beforeEach {
                        delegateSpy.testSuiteOutcomes = [.failed]
                    }
                    
                    it("doesn't perform any mutation testing") {
                        let actualTestOutcomes = performMutationTesting(using: [], delegate: delegateSpy)
                        
                        expect(delegateSpy.methodCalls).to(equal([
                            "runTestSuite(savingResultsIntoFileNamed:)",
                            "abortTesting(reason:)"
                            ]))
                        expect(actualTestOutcomes).to(beEmpty())
                        expect(delegateSpy.abortReasons).to(equal([.initialTestingFailed]))
                    }
                }
                
                context("due to a build error") {
                    beforeEach {
                        delegateSpy.testSuiteOutcomes = [.buildError]
                    }
                    
                    it("doesn't perform any mutation testing") {
                        let actualTestOutcomes = performMutationTesting(using: [], delegate: delegateSpy)
                        
                        expect(delegateSpy.methodCalls).to(equal([
                            "runTestSuite(savingResultsIntoFileNamed:)",
                            "abortTesting(reason:)"
                            ]))
                        expect(actualTestOutcomes).to(beEmpty())
                        expect(delegateSpy.abortReasons).to(equal([.initialTestingFailed]))
                    }
                }
                
                context("due to a runtime error") {
                    beforeEach {
                        delegateSpy.testSuiteOutcomes = [.runtimeError]
                    }
                    
                    it("doesn't perform any mutation testing") {
                        let actualTestOutcomes = performMutationTesting(using: [], delegate: delegateSpy)
                        
                        expect(delegateSpy.methodCalls).to(equal([
                            "runTestSuite(savingResultsIntoFileNamed:)",
                            "abortTesting(reason:)"
                            ]))
                        expect(actualTestOutcomes).to(beEmpty())
                        expect(delegateSpy.abortReasons).to(equal([.initialTestingFailed]))
                    }
                }
            }
            
            context("when it encounters 5 consecutive build errors in a project-under-test") {
                
                beforeEach {
                    delegateSpy.testSuiteOutcomes = [.passed, .buildError, .buildError, .buildError, .buildError, .buildError]
                }
                
                it("aborts testing after the maximum number of attempts is reached") {
                    let actualTestOutcomes = performMutationTesting(using: Array(repeating: mutationOperatorStub, count: 5), delegate: delegateSpy)
                    
                    expect(delegateSpy.methodCalls).to(equal([
                        // Base test suite run
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        // First operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)",
                        // Second operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)",
                        // Third operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)",
                        // Fourth operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)",
                        // Fifth operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)",
                        // Abort
                        "abortTesting(reason:)"
                        ]))
                    
                    expect(delegateSpy.backedUpFilePaths.count).to(equal(5))
                    expect(delegateSpy.restoredFilePaths.count).to(equal(5))
                    expect(delegateSpy.backedUpFilePaths).to(equal(delegateSpy.restoredFilePaths))
                    
                    expect(delegateSpy.mutatedFileContents.first).to(equal(SyntaxFactory.makeReturnKeyword().description))
                    expect(delegateSpy.mutatedFilePaths.first).to(equal("a file path"))
                    
                    expect(actualTestOutcomes).to(equal([]))
                    expect(delegateSpy.abortReasons).to(equal([.tooManyBuildErrors]))
                }
            }
            
            context("when it doesn't encounter 5 consecutive build errors in a project-under-test") {
                
                beforeEach {
                    delegateSpy.testSuiteOutcomes = [.passed, .buildError, .buildError, .buildError, .buildError, .failed, .passed]
                }
                
                it("performs mutation testing normally") {
                    
                    let expectedBuildErrorOutcome = MutationTestOutcome(testSuiteOutcome: .buildError,
                                                                  mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "a file path", position: .firstPosition),
                                                                  operatorDescription: "")
                    let expectedFailingOutcome = MutationTestOutcome(testSuiteOutcome: .failed,
                                                                     mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "a file path", position: .firstPosition),
                                                                     operatorDescription: "")
                    let expectedTestOutcomes = Array(repeating: expectedBuildErrorOutcome, count: 4) + [expectedFailingOutcome]
                    
                    
                    let actualTestOutcomes = performMutationTesting(using: Array(repeating: mutationOperatorStub, count: 5), delegate: delegateSpy)
                    
                    
                    expect(delegateSpy.methodCalls).to(equal([
                        // Base test suite run
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        // First operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)",
                        // Second operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)",
                        // Third operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)",
                        // Fourth operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)",
                        // Fifth operator
                        "backupFile(at:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(savingResultsIntoFileNamed:)",
                        "restoreFile(at:)"
                        ]))
                    
                    expect(delegateSpy.backedUpFilePaths.count) == 5
                    expect(delegateSpy.restoredFilePaths.count) == 5
                    expect(delegateSpy.backedUpFilePaths) == delegateSpy.restoredFilePaths
                    
                    expect(delegateSpy.mutatedFileContents.first) == SyntaxFactory.makeReturnKeyword().description
                    expect(delegateSpy.mutatedFilePaths.first) == "a file path"
                    
                    expect(actualTestOutcomes) == expectedTestOutcomes
                }
            }
        }
    }
}

typealias NotificationPayload = (name: NSNotification.Name, object: Any?, userInfo: [AnyHashable: Any]?)
private class NotificationCenterSpy: NotificationCenter {
    var methodCalls = [String]()
    var payloads = [NotificationPayload]()

    override func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        methodCalls.append(#function)
        payloads.append((name: aName, object: anObject, userInfo: aUserInfo))
    }
}
