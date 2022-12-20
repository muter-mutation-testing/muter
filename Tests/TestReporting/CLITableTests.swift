import XCTest

@testable import muterCore

final class CLITableTests: XCTestCase {
    private let fileColumn = CLITable.Column(title: "File name", rows: [
        CLITable.Row(value: "file 1.swift"),
        CLITable.Row(value: "file2.swift"),
        CLITable.Row(value: "file 3.swift"),
        CLITable.Row(value: "file4.swift"),
    ])

    private let mutationScoreColumn = CLITable.Column(title: "Mutation Score", rows: [
        CLITable.Row(value: "60"),
        CLITable.Row(value: "0"),
        CLITable.Row(value: "100"),
        CLITable.Row(value: "55"),
    ])

    private let numberOfAppliedMutationsColumn = CLITable.Column(title: "# of Generated Mutants", rows: [
        CLITable.Row(value: "1"),
        CLITable.Row(value: "2"),
        CLITable.Row(value: "3"),
        CLITable.Row(value: "4"),
    ])

    private lazy var columns = [
        fileColumn,
        numberOfAppliedMutationsColumn,
        mutationScoreColumn,
    ]

    func test_cliTableWithPaddingOfThree() {
        let expectedCLITable = """
            File name      # of Generated Mutants   Mutation Score
            ---------      ----------------------   --------------
            file 1.swift   1                        60
            file2.swift    2                        0
            file 3.swift   3                        100
            file4.swift    4                        55
            """

        XCTAssertTrue(CLITable(padding: 3, columns: columns).description.contains(expectedCLITable))
    }

    func test_cliTableWithPaddingOfSix() {
        let expectedCLITable = """
            File name         # of Generated Mutants      Mutation Score
            ---------         ----------------------      --------------
            file 1.swift      1                           60
            file2.swift       2                           0
            file 3.swift      3                           100
            file4.swift       4                           55
            """

        XCTAssertTrue(CLITable(padding: 6, columns: columns).description.contains(expectedCLITable))
    }

    func test_differentPaddings() {
        XCTAssertNotEqual(
            CLITable(padding: 4, columns: columns).description,
            CLITable(padding: 3, columns: columns).description
        )
    }

    func test_resizeBasedOnRowContents() {
        XCTAssertEqual(fileColumn.width, 12)
        XCTAssertEqual(numberOfAppliedMutationsColumn.width, 22)
    }

    func test_widthWithEmptyRows() {
        XCTAssertEqual(CLITable.Column(title: "", rows: []).width, 0)

        let emptyColumnWithValues = CLITable.Column(title: "", rows: [CLITable.Row(value: "")])
        XCTAssertEqual(emptyColumnWithValues.width, 0)
    }

    func test_emptyString() {
        XCTAssertEqual(CLITable.Column(title: "", rows: []).description, "")
    }
}
