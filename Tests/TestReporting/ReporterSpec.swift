import Quick
import Nimble
import Foundation
import TestingExtensions
import Rainbow

@testable import muterCore

class ReporterSpec: QuickSpec {
    override func spec() {
        let outcomes = [
            MutationTestOutcome(
                testSuiteOutcome: .passed,
                mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/project/file3.swift", position: .firstPosition),
                mutationSnapshot: MutationOperatorSnapshot(before: "!=", after: "==", description: "from != to =="),
                originalProjectDirectoryUrl: URL(string: "/user/project")!
            )
        ]
        
        describe("reporter choice") {
            context("when they want a json") {
                it("then return it") {
                    expect(makeReporter(
                            shouldOutputJson: true,
                            shouldOutputXcode: false,
                            shouldOutputHtml: false)
                    ).to(beAKindOf(JsonReporter.self))
                }
            }
            
            context("when they want xcode") {
                it("then return it") {
                    expect(makeReporter(
                            shouldOutputJson: false,
                            shouldOutputXcode: true,
                            shouldOutputHtml: false)
                    ).to(beAKindOf(XcodeReporter.self))
                }
            }
            
            context("when they want plain text") {
                it("then return it") {
                    expect(makeReporter(
                            shouldOutputJson: false,
                            shouldOutputXcode: false,
                            shouldOutputHtml: false)
                    ).to(beAKindOf(PlainTextReporter.self))
                }
            }

            context("when they want an html") {
                it("then return it") {
                    expect(makeReporter(
                            shouldOutputJson: false,
                            shouldOutputXcode: false,
                            shouldOutputHtml: true)
                    ).to(beAKindOf(HTMLReporter.self))
                }
            }
        }

        describe("text reporter") {
            it("returns the report in text format") {
                let plainText = PlainTextReporter().report(from: outcomes)
                expect(plainText).to(
                    equalWithDiff(
                        """
                        Muter finished running!

                        Here's your test report:
                        
                        --------------------------
                        Applied Mutation Operators
                        --------------------------
                        
                        These are all of the ways that Muter introduced changes into your code.
                        
                        In total, Muter introduced 1 mutants in 1 files.
                        
                        File            Applied Mutation Operator       Mutation Test Result
                        ----            -------------------------       --------------------
                        file3.swift:0   RelationalOperatorReplacement   mutant survived
                        
                        
                        --------------------
                        Mutation Test Scores
                        --------------------
                        
                        These are the mutation scores for your test suite, as well as the files that had mutants introduced into them.
                        
                        Mutation scores ignore build errors.
                        
                        Of the 1 mutants introduced into your code, your test suite killed 0.
                        Mutation Score of Test Suite: 0%
                        
                        File          # of Introduced Mutants   Mutation Score
                        ----          -----------------------   --------------
                        file3.swift   1                         0

                        """
                    )
                )
            }
        }

        describe("xcode reporter") {
            let outcomes = outcomes + [MutationTestOutcome(testSuiteOutcome: .failed,
                                             mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/project/file4.swift", position: .firstPosition),
                                             mutationSnapshot: MutationOperatorSnapshot(before: "==", after: "!=", description: "changed from == to !="),
                                             originalProjectDirectoryUrl: URL(string: "/user/project")!),
                         MutationTestOutcome(testSuiteOutcome: .passed,
                                             mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/project/file5.swift", position: .firstPosition),
                                             mutationSnapshot: MutationOperatorSnapshot(before: "==", after: "!=", description: "changed from == to !="),
                                             originalProjectDirectoryUrl: URL(string: "/user/project")!)]

            context("with footer-only not requested") {
                it("returns the report in xcode format") {
                    expect(XcodeReporter().report(from: outcomes)).to(equalWithDiff(
                        """
                        Mutation score: 33
                        Mutants introduced into your code: 3
                        Number of killed mutants: 1
                        """
                    ))
                }
            }
        }

        describe("json reporter") {
            it("returns the report in json format") {
                let json = JsonReporter().report(from: outcomes)

                guard let data = json.data(using: .utf8),
                    let actualReport = try? JSONDecoder().decode(MuterTestReport.self, from: data) else {
                        fail("Expected a valid JSON object, but didn't get one")
                        return
                }

                // The reports differ and can't be equated easily as we do not persist the path of a file report.
                // Basically, when we deserialize it, it's missing a field (`path`).
                expect(actualReport.totalAppliedMutationOperators) == 1
                expect(actualReport.fileReports.first?.fileName) == "file3.swift"
            }
        }
    }
}
