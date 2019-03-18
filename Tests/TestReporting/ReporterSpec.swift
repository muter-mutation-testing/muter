import Quick
import Nimble
import Foundation
import TestingExtensions
@testable import muterCore

class ReporterSpec: QuickSpec {
    override func spec() {

        let outcomes = [
            MutationTestOutcome(testSuiteOutcome: .passed,
                                appliedMutation: .negateConditionals,
                                filePath: "/tmp/file3.swift",
                                position: .firstPosition,
                                operatorDescription: "changed from != to ==")
        ]

        describe("text reporter") {
            it("returns the report in text format") {
                expect(Reporter.plainText.generateReport(from: outcomes)).toNot(beEmpty())
            }
        }

        describe("xcode reporter") {
            it("returns the report in xcode format") {
                let outcomes = outcomes + [MutationTestOutcome(testSuiteOutcome: .failed,
                                                               appliedMutation: .negateConditionals,
                                                               filePath: "/tmp/file4.swift",
                                                               position: .firstPosition,
                                                               operatorDescription: "changed from == to !="),
                                           MutationTestOutcome(testSuiteOutcome: .passed,
                                                               appliedMutation: .negateConditionals,
                                                               filePath: "/tmp/file5.swift",
                                                               position: .firstPosition,
                                                               operatorDescription: "changed from == to !=")]
                
                expect(Reporter.xcode.generateReport(from: outcomes)) == """
                /tmp/file3.swift:0:0: warning: Your test suite did not kill this mutant: changed from != to ==
                /tmp/file5.swift:0:0: warning: Your test suite did not kill this mutant: changed from == to !=
                """
            }
        }

        describe("json reporter") {
            it("returns the report in json format") {

                let json = Reporter.json.generateReport(from: outcomes)

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
