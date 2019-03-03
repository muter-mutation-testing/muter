import Quick
import Nimble
import Foundation
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
                expect(textReporter(report: report)).toNot(beEmpty())
            }
        }

        describe("xcode reporter") {
            it("returns the report in xcode format") {
                expect(xcodeReporter(report: report)).to(equal("/tmp/file3.swift:0:0: warning: \"Your test suite did not kill this mutant: negate conditionals\""))
            }
        }

        describe("json reporter") {
            it("returns the report in json format") {

                let json = jsonReporter(report: report)

                guard let data = json.data(using: .utf8),
                    let actualReport = try? JSONDecoder().decode(MuterTestReport.self, from: data) else {
                        fail("Expected a valid JSON object, but didn't get one")
                        return
                }

                // The reports differ and can't be equated easily as we do not persist the path of a file report.
                // Basically, when we deserialize it, it's missing a field (`path`).
                expect(actualReport.totalAppliedMutationOperators).to(equal(report.totalAppliedMutationOperators))
                expect(actualReport.fileReports.first?.fileName).to(equal(report.fileReports.first?.fileName))
            }
        }
    }
}
