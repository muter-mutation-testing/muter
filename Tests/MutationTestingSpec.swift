@testable import muterCore
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
                mutationOperatorStub = MutationOperator(id: .negateConditionals,
                                                        filePath: "a file path",
                                                        position: .firstPosition,
                                                        source: SyntaxFactory.makeReturnKeyword()) { return $0 }
            }

            context("when the baseline test run passes") {

                beforeEach {
                    delegateSpy.testSuiteOutcomes = [.passed, .failed, .failed]
                }

                it("performs a mutation test for every mutation operator") {
                    let expectedTestOutcomes = [
                        MutationTestOutcome(testSuiteOutcome: .failed,
                                            appliedMutation: .negateConditionals,
                                            filePath: "a file path",
                                            position: .firstPosition,
                                            operatorDescription: ""),
                        MutationTestOutcome(testSuiteOutcome: .failed,
                                            appliedMutation: .negateConditionals,
                                            filePath: "a file path",
                                            position: .firstPosition,
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
            
            context("when it fails to build a project-under-test 5 times in a row") {

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

            context("when it fails to build a project-under-test less than 5 times in a row") {

                beforeEach {
                    delegateSpy.testSuiteOutcomes = [.passed, .buildError, .buildError, .buildError, .buildError, .failed, .passed]
                }

                it("performs mutation testing normally") {
                    let expectedTestOutcomes = [
                        MutationTestOutcome(testSuiteOutcome: .buildError,
                                            appliedMutation: .negateConditionals,
                                            filePath: "a file path",
                                            position: .firstPosition,
                                            operatorDescription: ""),
                        MutationTestOutcome(testSuiteOutcome: .buildError,
                                            appliedMutation: .negateConditionals,
                                            filePath: "a file path",
                                            position: .firstPosition,
                                            operatorDescription: ""),
                        MutationTestOutcome(testSuiteOutcome: .buildError,
                                            appliedMutation: .negateConditionals,
                                            filePath: "a file path",
                                            position: .firstPosition,
                                            operatorDescription: ""),
                        MutationTestOutcome(testSuiteOutcome: .buildError,
                                            appliedMutation: .negateConditionals,
                                            filePath: "a file path",
                                            position: .firstPosition,
                                            operatorDescription: ""),
                        MutationTestOutcome(testSuiteOutcome: .failed,
                                            appliedMutation: .negateConditionals,
                                            filePath: "a file path",
                                            position: .firstPosition,
                                            operatorDescription: ""),
                    ]

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

                    expect(delegateSpy.backedUpFilePaths.count).to(equal(5))
                    expect(delegateSpy.restoredFilePaths.count).to(equal(5))
                    expect(delegateSpy.backedUpFilePaths).to(equal(delegateSpy.restoredFilePaths))

                    expect(delegateSpy.mutatedFileContents.first).to(equal(SyntaxFactory.makeReturnKeyword().description))
                    expect(delegateSpy.mutatedFilePaths.first).to(equal("a file path"))

                    expect(actualTestOutcomes).to(equal(expectedTestOutcomes))
                }
            }
        }
    }
}
