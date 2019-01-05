@testable import muterCore
import testingCore

import class Foundation.Bundle
import XCTest

final class TestReportGenerationTests: XCTestCase {
	func test_generatingAppliedMutationsTable() {
		
		let expectedTable = Table(padding: 3, columns: [
			Table.Column(title: "File", rows: [
				Table.Row(value: "file1.swift"),
				Table.Row(value: "file1.swift"),
				Table.Row(value: "file1.swift"),
				Table.Row(value: "file2.swift"),
				Table.Row(value: "file2.swift"),
				Table.Row(value: "file3.swift"),
				Table.Row(value: "file3.swift"),
				Table.Row(value: "file3.swift"),
				Table.Row(value: "file4.swift"),
			]),
			Table.Column(title: "Position", rows: [
				Table.Row(value: "Line: 0, Column: 0"),
				Table.Row(value: "Line: 0, Column: 0"),
				Table.Row(value: "Line: 0, Column: 0"),
				Table.Row(value: "Line: 0, Column: 0"),
				Table.Row(value: "Line: 0, Column: 0"),
				Table.Row(value: "Line: 0, Column: 0"),
				Table.Row(value: "Line: 0, Column: 0"),
				Table.Row(value: "Line: 0, Column: 0"),
				Table.Row(value: "Line: 0, Column: 0"),
			]),
			Table.Column(title: "Applied Mutation Operator", rows: [
				Table.Row(value: "SomeMutation"),
				Table.Row(value: "SomeMutation"),
				Table.Row(value: "SomeMutation"),
				Table.Row(value: "SomeOtherMutation"),
				Table.Row(value: "SomeOtherMutation"),
				Table.Row(value: "SomeMutation"),
				Table.Row(value: "SomeMutation"),
				Table.Row(value: "SomeMutation"),
				Table.Row(value: "SomeMutation"),
				]),
			Table.Column(title: "Mutation Test Result", rows: [
				Table.Row(value: "passed"),
				Table.Row(value: "passed"),
				Table.Row(value: "failed"),
				Table.Row(value: "passed"),
				Table.Row(value: "passed"),
				Table.Row(value: "passed"),
				Table.Row(value: "failed"),
				Table.Row(value: "failed"),
				Table.Row(value: "failed"),
			]),
		])
		
		let generatedTable = generateAppliedMutationsTable(from:
			self.exampleMutationTestResults) { $0 }
		
		XCTAssertEqual(generatedTable, expectedTable)
	}
	
	func test_generatingTheMutationScoresTable() {
		let expectedTable = Table(padding: 3, columns: [
			Table.Column(title: "File", rows: [
				Table.Row(value: "file1.swift"),
				Table.Row(value: "file2.swift"),
				Table.Row(value: "file3.swift"),
				Table.Row(value: "file4.swift"),
				]),
			Table.Column(title: "# of Applied Mutation Operators", rows: [
				Table.Row(value: "3"),
				Table.Row(value: "2"),
				Table.Row(value: "3"),
				Table.Row(value: "1"),
			]),
			Table.Column(title: "Mutation Score", rows: [
				Table.Row(value: "66"),
				Table.Row(value: "100"),
				Table.Row(value: "33"),
				Table.Row(value: "0"),
			])
		])
		
		let generatedTable = generateMutationScoresTable(from: self.exampleMutationTestResults) { $0 }
		XCTAssertEqual(generatedTable, expectedTable)
	}
	
	func test_applyingColorToMutationTestResults() {
		let rows = [
			Table.Row(value: "passed"),
			Table.Row(value: "failed"),
		]
		
		let coloredRows = applyMutationTestResultsColor(to: rows)
		
		XCTAssertNotEqual(rows, coloredRows)
		XCTAssertEqual(rows.count, coloredRows.count)
		XCTAssert(coloredRows.first?.value.contains(rows.first?.value ?? ""))
		XCTAssert(coloredRows.last?.value.contains(rows.last?.value ?? ""))
	}
	
	func test_applyingColorToMutationScores() {
		let rows = [
			Table.Row(value: "0"),
			Table.Row(value: "26"),
			Table.Row(value: "51"),
			Table.Row(value: "76"),
		]
		
		
		let coloredRows = applyMutationScoreColor(to: rows)
		
		XCTAssertNotEqual(rows, coloredRows)
		XCTAssertEqual(rows.count, coloredRows.count)
		XCTAssert(coloredRows.first?.value.contains(rows.first?.value ?? ""))
		XCTAssert(coloredRows.last?.value.contains(rows.last?.value ?? ""))
	}
}

enum CustomTestFailure: Error {
	case failure
}

func XCTAssert(_ value: Bool?) {
	guard let unwrappedValue = value,
		unwrappedValue == true else {
			XCTFail()
			return
	}
}
