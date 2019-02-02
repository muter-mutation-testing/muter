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
                    delegateSpy.testSuiteResults = [.passed, .failed, .failed]
                }

                it("performs a mutation test for every mutation operator") {
                    let expectedResults = [
                        MutationTestOutcome(testSuiteResult: .failed,
                                            appliedMutation: "Negate Conditionals",
                                            filePath: "a file path",
                                            position: .firstPosition),
                        MutationTestOutcome(testSuiteResult: .failed,
                                            appliedMutation: "Negate Conditionals",
                                            filePath: "a file path",
                                            position: .firstPosition),
                    ]

                    let actualResults = performMutationTesting(using: [mutationOperatorStub, mutationOperatorStub], delegate: delegateSpy)

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

                    expect(actualResults).to(equal(expectedResults))
                }
            }

            context("when the baseline test run fails to build 5 times in a row") {

                beforeEach {
                    delegateSpy.testSuiteResults = [.passed, .buildError, .buildError, .buildError, .buildError, .buildError]
                }

                it("bails after max attempts reached") {
                    let actualResults = performMutationTesting(using: Array(repeating: mutationOperatorStub, count: 5), delegate: delegateSpy)

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
                        // Bail
                        "tooManyBuildErrors()"
                    ]))

                    expect(delegateSpy.backedUpFilePaths.count).to(equal(5))
                    expect(delegateSpy.restoredFilePaths.count).to(equal(5))
                    expect(delegateSpy.backedUpFilePaths).to(equal(delegateSpy.restoredFilePaths))

                    expect(delegateSpy.mutatedFileContents.first).to(equal(SyntaxFactory.makeReturnKeyword().description))
                    expect(delegateSpy.mutatedFilePaths.first).to(equal("a file path"))

                    expect(actualResults).to(beEmpty())
                }
            }

            context("when the baseline test run does not pass") {

                context("due to a failing test") {
                    beforeEach {
                        delegateSpy.testSuiteResults = [.failed]
                    }

                    it("doesn't perform any mutation testing") {
                        let actualResults = performMutationTesting(using: [], delegate: delegateSpy)

                        expect(delegateSpy.methodCalls).to(equal([
                            "runTestSuite(savingResultsIntoFileNamed:)",
                            "abortTesting()"
                        ]))
                        expect(actualResults).to(beEmpty())
                    }
                }

                context("due to a build error") {
                    beforeEach {
                        delegateSpy.testSuiteResults = [.buildError]
                    }

                    it("doesn't perform any mutation testing") {
                        let actualResults = performMutationTesting(using: [], delegate: delegateSpy)

                        expect(delegateSpy.methodCalls).to(equal([
                            "runTestSuite(savingResultsIntoFileNamed:)",
                            "abortTesting()"
                        ]))
                        expect(actualResults).to(beEmpty())
                    }
                }

                context("due to a runtime error") {
                    beforeEach {
                        delegateSpy.testSuiteResults = [.runtimeError]
                    }

                    it("doesn't perform any mutation testing") {
                        let actualResults = performMutationTesting(using: [], delegate: delegateSpy)

                        expect(delegateSpy.methodCalls).to(equal([
                            "runTestSuite(savingResultsIntoFileNamed:)",
                            "abortTesting()"
                        ]))
                        expect(actualResults).to(beEmpty())
                    }
                }
            }
        }

        describe("mutationScore") {
            it("calculates a mutation score from a set of test suite results") {
                expect(mutationScore(from: [])).to(equal(-1))

                expect(mutationScore(from: [.passed])).to(equal(0))
                expect(mutationScore(from: [.failed])).to(equal(100))

                expect(mutationScore(from: [.passed, .failed])).to(equal(50))
                expect(mutationScore(from: [.passed, .failed, .failed])).to(equal(66))

                expect(mutationScore(from: [.passed, .runtimeError])).to(equal(50))

                expect(mutationScore(from: [.passed, .failed, .buildError])).to(equal(50))
            }

            it("calculates a mutation score for each mutated file from a mutation test run") {
                let expectedMutationScores = [
                    "file1.swift": 66,
                    "file2.swift": 100,
                    "file3.swift": 33,
                    "file 4.swift": 0
                ]

                expect(mutationScoreOfFiles(from: self.exampleMutationTestResults)).to(equal(expectedMutationScores))
            }
        }
    }
}
