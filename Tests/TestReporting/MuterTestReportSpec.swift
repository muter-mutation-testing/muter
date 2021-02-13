import Quick
import Nimble
import Foundation
@testable import muterCore

class MuterTestReportSpec: QuickSpec {
    override func spec() {
        describe("MuterTestReport") {
            context("when given a nonempty collection of MutationTestOutcomes") {
                it("calculates all its fields as part of its initialization") {
                    let outcomes = self.exampleMutationTestResults + [MutationTestOutcome(
                                                                        testSuiteOutcome: .failed,
                                                                        mutationPoint: MutationPoint(mutationOperatorId: .ror,
                                                                        filePath: "/tmp/a module.swift", position: .firstPosition),
                                                                        mutationSnapshot: .make(
                                                                            before: "==",
                                                                            after: "!=",
                                                                            description: "changed from == to !="
                                                                        )
                    ),]

                    let report = MuterTestReport(from: outcomes)
                    expect(report.globalMutationScore).to(equal(60))
                    expect(report.totalAppliedMutationOperators).to(equal(10))
                    expect(report.fileReports).to(haveCount(5))
                    expect(report.fileReports) == [
                        FileReportProvider.expectedFileReport1,
                        FileReportProvider.expectedFileReport2,
                        FileReportProvider.expectedFileReport3,
                        FileReportProvider.expectedFileReport4,
                        FileReportProvider.expectedFileReport5,
                    ]
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
                    "/tmp/file1.swift": 66,
                    "/tmp/file2.swift": 100,
                    "/tmp/file3.swift": 33,
                    "/tmp/file 4.swift": 0,
                ]

                expect(mutationScoresOfFiles(from: self.exampleMutationTestResults)).to(equal(expectedMutationScores))
            }
        }
    }
}
