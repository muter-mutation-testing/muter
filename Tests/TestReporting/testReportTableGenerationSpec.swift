@testable import muterCore

import Quick
import Nimble

class TestReportTableGenerationSpec: QuickSpec {
    override func spec() {
        describe("Test Report Generation") {

            let fileReports = [
                MuterTestReport.FileReport(fileName: "file1.swift", path: "/tmp/file1.swift", mutationScore: 66, appliedOperators: [
                    MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, description: "", testSuiteOutcome: .failed),
                    MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, description: "", testSuiteOutcome: .failed),
                    MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, description: "", testSuiteOutcome: .passed)
                ]),
                MuterTestReport.FileReport(fileName: "file2.swift", path: "/tmp/file2.swift", mutationScore: 100, appliedOperators: [
                    MuterTestReport.AppliedMutationOperator(id: .removeSideEffects, position: .firstPosition, description: "", testSuiteOutcome: .failed),
                    MuterTestReport.AppliedMutationOperator(id: .removeSideEffects, position: .firstPosition, description: "", testSuiteOutcome: .failed)
                ]),
                MuterTestReport.FileReport(fileName: "file3.swift", path: "/tmp/file3.swift", mutationScore: 33, appliedOperators: [
                    MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, description: "", testSuiteOutcome: .failed),
                    MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, description: "", testSuiteOutcome: .passed),
                    MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, description: "", testSuiteOutcome: .passed)
                ]),
                MuterTestReport.FileReport(fileName: "file 4.swift", path: "/tmp/file 4.swift", mutationScore: 0, appliedOperators: [
                    MuterTestReport.AppliedMutationOperator(id: .negateConditionals, position: .firstPosition, description: "", testSuiteOutcome: .passed)
                ])
            ]

            describe("the applied mutation operators table") {
                it("contains information about which mutation operators were applied, as well as the outcome of applying that operator") {
                    let expectedCLITable = CLITable(padding: 3, columns: [
                        CLITable.Column(title: "File", rows: [
                            CLITable.Row(value: "file1.swift:0"),
                            CLITable.Row(value: "file1.swift:0"),
                            CLITable.Row(value: "file1.swift:0"),
                            CLITable.Row(value: "file2.swift:0"),
                            CLITable.Row(value: "file2.swift:0"),
                            CLITable.Row(value: "file3.swift:0"),
                            CLITable.Row(value: "file3.swift:0"),
                            CLITable.Row(value: "file3.swift:0"),
                            CLITable.Row(value: "file 4.swift:0"),
                        ]),
                        CLITable.Column(title: "Applied Mutation Operator", rows: [
                            CLITable.Row(value: "Negate Conditionals"),
                            CLITable.Row(value: "Negate Conditionals"),
                            CLITable.Row(value: "Negate Conditionals"),
                            CLITable.Row(value: "Remove Side Effects"),
                            CLITable.Row(value: "Remove Side Effects"),
                            CLITable.Row(value: "Negate Conditionals"),
                            CLITable.Row(value: "Negate Conditionals"),
                            CLITable.Row(value: "Negate Conditionals"),
                            CLITable.Row(value: "Negate Conditionals"),
                        ]),
                        CLITable.Column(title: "Mutation Test Result", rows: [
                            CLITable.Row(value: "mutant killed (test failure)"),
                            CLITable.Row(value: "mutant killed (test failure)"),
                            CLITable.Row(value: "mutant survived"),
                            CLITable.Row(value: "mutant killed (test failure)"),
                            CLITable.Row(value: "mutant killed (test failure)"),
                            CLITable.Row(value: "mutant killed (test failure)"),
                            CLITable.Row(value: "mutant survived"),
                            CLITable.Row(value: "mutant survived"),
                            CLITable.Row(value: "mutant survived"),
                        ]),
                    ])

                    let generatedCLITable = generateAppliedMutationsCLITable(from: fileReports, coloringFunction: { $0 })

                    expect(generatedCLITable).to(equal(expectedCLITable))
                }
            }

            describe("the mutation scores table") {
                it("contains information about the mutation score and number of applied mutation operators for every file") {
                    let expectedCLITable = CLITable(padding: 3, columns: [
                        CLITable.Column(title: "File", rows: [
                            CLITable.Row(value: "file1.swift"),
                            CLITable.Row(value: "file2.swift"),
                            CLITable.Row(value: "file3.swift"),
                            CLITable.Row(value: "file 4.swift"),
                        ]),
                        CLITable.Column(title: "# of Applied Mutation Operators", rows: [
                            CLITable.Row(value: "3"),
                            CLITable.Row(value: "2"),
                            CLITable.Row(value: "3"),
                            CLITable.Row(value: "1"),
                        ]),
                        CLITable.Column(title: "Mutation Score", rows: [
                            CLITable.Row(value: "66"),
                            CLITable.Row(value: "100"),
                            CLITable.Row(value: "33"),
                            CLITable.Row(value: "0"),
                        ])
                    ])

                    let generatedCLITable = generateMutationScoresCLITable(from: fileReports, coloringFunction: { $0 })

                    expect(generatedCLITable).to(equal(expectedCLITable))
                }
            }

            describe("coloring test results") {
                it("colors whether or not a test has failed") {
                    let rows = [
                        CLITable.Row(value: "passed"),
                        CLITable.Row(value: "failed"),
                    ]

                    let coloredRows = applyMutationTestResultsColor(to: rows)

                    expect(coloredRows.count).to(equal(rows.count))
                    expect(coloredRows.first?.value).to(contain(rows.first!.value))
                    expect(coloredRows.last?.value).to(contain(rows.last!.value))
                }

                it("colors mutation scores based on how close to 100 they are") {
                    let rows = [
                        CLITable.Row(value: "0"),
                        CLITable.Row(value: "26"),
                        CLITable.Row(value: "51"),
                        CLITable.Row(value: "76"),
                    ]

                    let coloredRows = applyMutationScoreColor(to: rows)

                    expect(coloredRows.count).to(equal(rows.count))
                    expect(coloredRows.first?.value).to(contain(rows.first!.value))
                    expect(coloredRows.last?.value).to(contain(rows.last!.value))
                }
            }
        }
    }
}
