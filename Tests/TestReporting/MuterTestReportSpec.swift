import Quick
import Nimble
import TestingExtensions
@testable import muterCore

class MuterTestReportSpec: QuickSpec {
    override func spec() {
        describe("MuterTestReport") {
            context("when given a nonempty collection of MutationTestOutcomes") {
                it("calculates all its fields as part of its initialization") {
                    
                    let outcomes = self.exampleMutationTestResults + [MutationTestOutcome(testSuiteOutcome: .failed,
                                                                                          appliedMutation: .negateConditionals,
                                                                                          filePath: "a module.swift",
                                                                                          position: .firstPosition)]
                    let report = MuterTestReport(from: outcomes)

                    expect(report.globalMutationScore).to(equal(60))
                    expect(report.totalAppliedMutationOperators).to(equal(10))
                    expect(report.fileReports).to(haveCount(5))

                    expect(report.fileReports).to(equal([
                        MuterTestReport.FileReport(fileName: "a module.swift", mutationScore: 100, appliedOperators: [
                            MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, testSuiteOutcome: .failed)
                            ]),
                        MuterTestReport.FileReport(fileName: "file 4.swift", mutationScore: 0, appliedOperators: [
                            MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, testSuiteOutcome: .passed)
                            ]),
                        MuterTestReport.FileReport(fileName: "file1.swift", mutationScore: 66, appliedOperators: [
                            MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, testSuiteOutcome: .failed),
                            MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, testSuiteOutcome: .failed),
                            MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, testSuiteOutcome: .passed)
                            ]),
                        MuterTestReport.FileReport(fileName: "file2.swift", mutationScore: 100, appliedOperators: [
                            MuterTestReport.AppliedMutationOperator(id: .removeSideEffects, position: .firstPosition, testSuiteOutcome: .failed),
                            MuterTestReport.AppliedMutationOperator(id: .removeSideEffects, position: .firstPosition, testSuiteOutcome: .failed)
                            ]),
                        MuterTestReport.FileReport(fileName: "file3.swift", mutationScore: 33, appliedOperators: [
                            MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, testSuiteOutcome: .failed),
                            MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, testSuiteOutcome: .passed),
                            MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, testSuiteOutcome: .passed)
                            ])
                        ]))
                    
                }
            }

            context("when given an empty collection of MutationTestOutcomes") {
                it("calculates all its fields to empty values as part of its initialization") {
                    let report = MuterTestReport(from: [])

                    expect(report.globalMutationScore).to(equal(-1))
                    expect(report.totalAppliedMutationOperators).to(equal(0))
                    expect(report.fileReports).to(beEmpty())
                }
            }
        }
        
        describe("mutationScore") {
            it("calculates a mutation score from a set of test suite results") {
                expect(mutationScore(from: [])).to(equal(-1))
                
                expect(mutationScore(from: [.passed])).to(equal(0))
                expect(mutationScore(from: [.failed])).to(equal(100))
                expect(mutationScore(from: [.runtimeError])).to(equal(100))
                
                expect(mutationScore(from: [.passed, .failed])).to(equal(50))
                expect(mutationScore(from: [.passed, .failed, .failed])).to(equal(66))
                
                expect(mutationScore(from: [.passed, .runtimeError])).to(equal(50))
                
                expect(mutationScore(from: [.passed, .failed, .buildError])).to(equal(50))
            }
            
            it("doesn't divide by zero if there is only a build error") {
                expect(mutationScore(from: [.buildError])).to(equal(0)) // This line can cause a crash if it fails
                expect(mutationScore(from: [.buildError, .buildError])).to(equal(0)) // This line can cause a crash if it fails
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

