@testable import muterCore
import Quick
import Nimble

class CLITableSpec: QuickSpec {
    override func spec() {
        let fileColumn = CLITable.Column(title: "File name", rows: [
            CLITable.Row(value: "file 1.swift"),
            CLITable.Row(value: "file2.swift"),
            CLITable.Row(value: "file 3.swift"),
            CLITable.Row(value: "file4.swift"),
        ])

        let mutationScoreColumn = CLITable.Column(title: "Mutation Score", rows: [
            CLITable.Row(value: "60"),
            CLITable.Row(value: "0"),
            CLITable.Row(value: "100"),
            CLITable.Row(value: "55"),
        ])

        let numberOfAppliedMutationsColumn = CLITable.Column(title: "# of Generated Mutants", rows: [
            CLITable.Row(value: "1"),
            CLITable.Row(value: "2"),
            CLITable.Row(value: "3"),
            CLITable.Row(value: "4"),
        ])

        let columns = [
            fileColumn,
            numberOfAppliedMutationsColumn,
            mutationScoreColumn,
        ]

        describe("CLITable") {
            describe("rendering an equally spaced table") {
                describe("with a padding of 3") {
                    it("renders variable-width columns with 3 spaces of padding between the columns") {
                        let expectedCLITable = """
							File name      # of Generated Mutants   Mutation Score
							---------      ----------------------   --------------
							file 1.swift   1                        60
							file2.swift    2                        0
							file 3.swift   3                        100
							file4.swift    4                        55
							"""

                        expect(CLITable(padding: 3, columns: columns).description).to(contain(expectedCLITable))
                    }
                }

                describe("with a padding of 6") {
                    it("renders variable-width columns with 6 spaces of padding between the columns") {
                        let expectedCLITable = """
							File name         # of Generated Mutants      Mutation Score
							---------         ----------------------      --------------
							file 1.swift      1                           60
							file2.swift       2                           0
							file 3.swift      3                           100
							file4.swift       4                           55
							"""

                        expect(CLITable(padding: 6, columns: columns).description).to(contain(expectedCLITable))}
                }
            }

            describe("comparing rendered tables with different paddings") {
                it("returns that they're not equal") {
                    expect(CLITable(padding: 4, columns: columns).description).toNot(equal(CLITable(padding: 3, columns: columns).description))
                }
            }
        }

        describe("CLITable.Column") {
            it("resizes itself based on the contents of its rows") {
                expect(fileColumn.width).to(equal(12))
                expect(numberOfAppliedMutationsColumn.width).to(equal(22))
            }

            it("has no width if it has no rows") {
                expect(CLITable.Column(title: "", rows: []).width).to(equal(0))

                let emptyColumnWithValues = CLITable.Column(title: "", rows: [CLITable.Row(value: "")])
                expect(emptyColumnWithValues.width).to(equal(0))
            }

            it("renders an empty string if it has no rows") {
                expect(CLITable.Column(title: "", rows: []).description).to(equal(""))
            }
        }
    }
}
