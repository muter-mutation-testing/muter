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
                delegateSpy.testSuiteResult = .failed
                mutationOperatorStub = MutationOperator(id: .negateConditionals,
                                                        filePath: "a file path",
                                                        position: .firstPosition,
                                                        source: SyntaxFactory.makeReturnKeyword()) { return $0 }
            }

            it("performs mutation test for every mutation operator") {
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
