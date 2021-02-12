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
        super.setUp()
    }

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
                    equalWithDiff(loadReport())
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

private func loadReport() -> String {
    guard let data = FileManager.default.contents(atPath: "\(ReporterSpec().fixturesDirectory)/TestReporting/testReport.txt"),
        let string = String(data: data, encoding: .utf8) else {
            fatalError("Unable to load reportfor testing")
    }

    return string
}
