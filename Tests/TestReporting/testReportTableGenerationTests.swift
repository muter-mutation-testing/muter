import XCTest

@testable import muterCore

final class TestReportTableGenerationTests: XCTestCase {
    private let fileReports = [
        FileReportProvider.expectedFileReport3,
        FileReportProvider.expectedFileReport4,
        FileReportProvider.expectedFileReport5,
        FileReportProvider.expectedFileReport2,
    ]

    func test_operatorsTable() {
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
                CLITable.Row(value: "RelationalOperatorReplacement"),
                CLITable.Row(value: "RelationalOperatorReplacement"),
                CLITable.Row(value: "RelationalOperatorReplacement"),
                CLITable.Row(value: "RemoveSideEffects"),
                CLITable.Row(value: "RemoveSideEffects"),
                CLITable.Row(value: "RelationalOperatorReplacement"),
                CLITable.Row(value: "RelationalOperatorReplacement"),
                CLITable.Row(value: "RelationalOperatorReplacement"),
                CLITable.Row(value: "RelationalOperatorReplacement"),
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

        let generatedCLITable = generateAppliedMutationOperatorsCLITable(from: fileReports, coloringFunction: { $0 })

        XCTAssertEqual(generatedCLITable, expectedCLITable)
    }

    func test_mutationScoreTable() {
        let expectedCLITable = CLITable(padding: 3, columns: [
            CLITable.Column(title: "File", rows: [
                CLITable.Row(value: "file1.swift"),
                CLITable.Row(value: "file2.swift"),
                CLITable.Row(value: "file3.swift"),
                CLITable.Row(value: "file 4.swift"),
            ]),
            CLITable.Column(title: "# of Introduced Mutants", rows: [
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
            ]),
        ])

        let generatedCLITable = generateMutationScoresCLITable(from: fileReports, coloringFunction: { $0 })

        XCTAssertEqual(generatedCLITable, expectedCLITable)
    }

    func test_coloringTestResults() {
        let rows = [
            CLITable.Row(value: "passed"),
            CLITable.Row(value: "failed"),
        ]

        let coloredRows = applyMutationTestResultsColor(to: rows)

        XCTAssertEqual(coloredRows.count, rows.count)
        XCTAssertNotNil(coloredRows.first?.value.contains(rows.first!.value))
        XCTAssertNotNil(coloredRows.last?.value.contains(rows.last!.value))
    }

    func test_coloringTestScore() {
        let rows = [
            CLITable.Row(value: "0"),
            CLITable.Row(value: "26"),
            CLITable.Row(value: "51"),
            CLITable.Row(value: "76"),
        ]

        let coloredRows = applyMutationScoreColor(to: rows)

        XCTAssertEqual(coloredRows.count, rows.count)
        XCTAssertNotNil(coloredRows.first?.value.contains(rows.first!.value))
        XCTAssertNotNil(coloredRows.last?.value.contains(rows.last!.value))
    }
}
