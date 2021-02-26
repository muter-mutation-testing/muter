import Quick
import Nimble
import Foundation
import TestingExtensions
import Rainbow

@testable import muterCore

class ReporterSpec: QuickSpec {
    override class func setUp() {
        // Rainbow is smart, it knows if the stdout is Xcode or the console.
        // We want it to be the console, otherwise the test results are going to differ when running from Xcode vs console
        Rainbow.outputTarget = .console
        Rainbow.enabled = false

        super.setUp()
    }

    override func spec() {
        let outcomes = [
            MutationTestOutcome.Mutation.make(
                testSuiteOutcome: .passed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/project/file3.swift",
                    position: .firstPosition
                ),
                snapshot: MutationOperatorSnapshot(before: "!=", after: "==", description: "from != to =="),
                originalProjectDirectoryUrl: URL(string: "/user/project")!
            ),
        ]

        describe("text reporter") {
            context("when outcome have coverage data") {
                it("adds coverage data to the report in text format") {
                    let plainText = PlainTextReporter()
                        .report(
                            from: .make(
                                outcome: .make(
                                    mutations: outcomes,
                                    coverage: .make(percent: 1)
                                )
                            )
                        )
                    expect(plainText).to(equalWithDiff(loadReportOfProjectWithCoverage()))
                }
            }
            
            context("when outcome doesn't have coverage data") {
                it("doesn't add coverage data to the report in text format") {
                    let plainText = PlainTextReporter()
                        .report(
                            from: .make(
                                outcome: .make(
                                    mutations: outcomes,
                                    coverage: .null
                                )
                            )
                        )
                    expect(plainText).to(equalWithDiff(loadReportOfProjectWithoutCoverage()))
                }
            }
        }

        describe("xcode reporter") {
            let outcomes = outcomes + [
                MutationTestOutcome.Mutation.make(
                    testSuiteOutcome: .failed,
                    point: MutationPoint(
                        mutationOperatorId: .ror,
                        filePath: "/tmp/project/file4.swift",
                        position: .firstPosition
                    ),
                    snapshot: MutationOperatorSnapshot(
                        before: "==",
                        after: "!=",
                        description: "changed from == to !="
                    ),
                    originalProjectDirectoryUrl: URL(string: "/user/project")!
                ),
                MutationTestOutcome.Mutation.make(
                    testSuiteOutcome: .passed,
                    point: MutationPoint(
                        mutationOperatorId: .ror,
                        filePath: "/tmp/project/file5.swift",
                        position: .firstPosition
                    ),
                    snapshot: MutationOperatorSnapshot(
                        before: "==",
                        after: "!=",
                        description: "changed from == to !="
                    ),
                    originalProjectDirectoryUrl: URL(string: "/user/project")!
                ),
            ]

            context("with footer-only not requested") {
                it("returns the report in xcode format") {
                    expect(XcodeReporter()
                            .report(
                                from: .make(mutations: outcomes)
                            )
                    ).to(equalWithDiff(
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
                let json = JsonReporter()
                    .report(
                        from: .make(mutations: outcomes)
                    )

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

private func loadReportOfProjectWithCoverage() -> String {
    guard let data = FileManager.default.contents(atPath: "\(ReporterSpec().fixturesDirectory)/TestReporting/testReportOfProjectWithCoverage.txt"),
        let string = String(data: data, encoding: .utf8) else {
            fatalError("Unable to load report for testing")
    }

    return string
}

private func loadReportOfProjectWithoutCoverage() -> String {
    guard let data = FileManager.default.contents(atPath: "\(ReporterSpec().fixturesDirectory)/TestReporting/testReportOfProjectWithoutCoverage.txt"),
        let string = String(data: data, encoding: .utf8) else {
            fatalError("Unable to load report for testing")
    }

    return string
}
