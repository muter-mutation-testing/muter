@testable import muterCore
import testingCore

import class Foundation.Bundle
import XCTest

final class TestReportGenerationTests: XCTestCase {
	func test_generatingAppliedMutationsTable() {
		
		let expectedTable = Table(padding: 3, columns: [
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
			self.exampleMutationTestResults)
		
		XCTAssertEqual(generatedTable, expectedTable)
	}
	
	func test_generatingTheMediationScoresTable() {
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
		
		let generatedTable = generateMutationScoresTable(from: self.exampleMutationTestResults)
		XCTAssertEqual(generatedTable, expectedTable)
	}
}
