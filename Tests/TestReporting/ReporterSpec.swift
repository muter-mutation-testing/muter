import Quick
import Nimble
import TestingExtensions
@testable import muterCore

class ReporterSpec: QuickSpec {
    override func spec() {
        let report = MuterTestReport(from: [
            MutationTestOutcome(
                testSuiteOutcome: .passed,
                appliedMutation: .negateConditionals,
                filePath: "/tmp/file3.swift",
                position: .firstPosition
            )
            ])

        describe("text reporter") {
            it("returns the report in text format") {
                expect(textReporter(report: report)).to(contain(
                    """
                    Muter finished running!


                    --------------------------
                    Applied Mutation Operators
                    --------------------------

                    These are all of the ways that Muter introduced changes into your code.

                    In total, Muter applied \(self.exampleMutationTestResults.count) mutation operators.
                    """
                ))
            }
        }

        describe("xcode reporter") {
            it("returns the report in xcode format") {
                expect(xcodeReporter(report: report)).to(equal("/tmp/file3.swift:0:0: warning: \"Your test suite did not kill this mutant: negate conditionals\""))
            }
        }

        describe("json reporter") {
            it("returns the report in json format") {
                expect(jsonReporter(report: report)).to(equal("{\"globalMutationScore\":0,\"numberOfKilledMutants\":0,\"fileReports\":[{\"path\":\"\\/tmp\\/file3.swift\",\"mutationScore\":0,\"fileName\":\"file3.swift\",\"appliedOperators\":[{\"id\":\"Negate Conditionals\",\"position\":{\"line\":0,\"utf8Offset\":0,\"column\":0},\"testSuiteOutcome\":\"passed\"}]}],\"totalAppliedMutationOperators\":1}"))
            }
        }
    }
}
