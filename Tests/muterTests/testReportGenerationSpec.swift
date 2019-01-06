@testable import muterCore
import testingCore

import Quick
import Nimble

class TestReportGenerationSpec: QuickSpec {
    override func spec() {
        describe("Test Report Generation") {
            describe("the applied mutation operators table") {
                it("contains information about which mutation operators were applied, as well as the outcome of applying that operator") {

                    let expectedCLITable = CLITable(padding: 3, columns: [
                        CLITable.Column(title: "File", rows: [
                            CLITable.Row(value: "file1.swift"),
                            CLITable.Row(value: "file1.swift"),
                            CLITable.Row(value: "file1.swift"),
                            CLITable.Row(value: "file2.swift"),
                            CLITable.Row(value: "file2.swift"),
                            CLITable.Row(value: "file3.swift"),
                            CLITable.Row(value: "file3.swift"),
                            CLITable.Row(value: "file3.swift"),
                            CLITable.Row(value: "file4.swift"),
                        ]),
                        CLITable.Column(title: "Position", rows: [
                            CLITable.Row(value: "Line: 0, Column: 0"),
                            CLITable.Row(value: "Line: 0, Column: 0"),
                            CLITable.Row(value: "Line: 0, Column: 0"),
                            CLITable.Row(value: "Line: 0, Column: 0"),
                            CLITable.Row(value: "Line: 0, Column: 0"),
                            CLITable.Row(value: "Line: 0, Column: 0"),
                            CLITable.Row(value: "Line: 0, Column: 0"),
                            CLITable.Row(value: "Line: 0, Column: 0"),
                            CLITable.Row(value: "Line: 0, Column: 0"),
                        ]),
                        CLITable.Column(title: "Applied Mutation Operator", rows: [
                            CLITable.Row(value: "SomeMutation"),
                            CLITable.Row(value: "SomeMutation"),
                            CLITable.Row(value: "SomeMutation"),
                            CLITable.Row(value: "SomeOtherMutation"),
                            CLITable.Row(value: "SomeOtherMutation"),
                            CLITable.Row(value: "SomeMutation"),
                            CLITable.Row(value: "SomeMutation"),
                            CLITable.Row(value: "SomeMutation"),
                            CLITable.Row(value: "SomeMutation"),
                        ]),
                        CLITable.Column(title: "Mutation Test Result", rows: [
                            CLITable.Row(value: "passed"),
                            CLITable.Row(value: "passed"),
                            CLITable.Row(value: "failed"),
                            CLITable.Row(value: "passed"),
                            CLITable.Row(value: "passed"),
                            CLITable.Row(value: "passed"),
                            CLITable.Row(value: "failed"),
                            CLITable.Row(value: "failed"),
                            CLITable.Row(value: "failed"),
                        ]),
                    ])

                    let generatedCLITable = generateAppliedMutationsCLITable(from: self.exampleMutationTestResults) { $0 }

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
                            CLITable.Row(value: "file4.swift"),
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

                    let generatedCLITable = generateMutationScoresCLITable(from: self.exampleMutationTestResults) { $0 }

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

                    expect(rows).toNot(equal(coloredRows))
                    expect(rows.count).to(equal(coloredRows.count))
                    expect(coloredRows.first?.value.contains(rows.first?.value ?? "")).to(beTrue())
                    expect(coloredRows.last?.value.contains(rows.last?.value ?? "")).to(beTrue())
                }

                it("colors mutation scores based on how close to 100 they are") {
                    let rows = [
                        CLITable.Row(value: "0"),
                        CLITable.Row(value: "26"),
                        CLITable.Row(value: "51"),
                        CLITable.Row(value: "76"),
                    ]

                    let coloredRows = applyMutationScoreColor(to: rows)

                    expect(rows).toNot(equal(coloredRows))
                    expect(rows.count).to(equal(coloredRows.count))
                    expect(coloredRows.first?.value.contains(rows.first?.value ?? "")).to(beTrue())
                    expect(coloredRows.last?.value.contains(rows.last?.value ?? "")).to(beTrue())
                }
            }
        }
    }
}
