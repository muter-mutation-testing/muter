import class Foundation.Bundle
@testable import muterCore
import XCTest

final class TableTests: XCTestCase {
	
	private let fileColumn = Table.Column(title: "File name", rows: [
		Table.Row(value: "file 1.swift"),
		Table.Row(value: "file2.swift"),
		Table.Row(value: "file 3.swift"),
		Table.Row(value: "file4.swift"),
	])
	
	private let mutationScoreColumn = Table.Column(title: "Mutation Score", rows: [
		Table.Row(value: "60"),
		Table.Row(value: "0"),
		Table.Row(value: "100"),
		Table.Row(value: "55"),
	])
	
	private let numberOfAppliedMutationsColumn = Table.Column(title: "# of Applied Mutations", rows: [
		Table.Row(value: "1"),
		Table.Row(value: "2"),
		Table.Row(value: "3"),
		Table.Row(value: "4")
	])
	
	var columns: [Table.Column]!
	
	override func setUp() {
		columns = [
			fileColumn,
			numberOfAppliedMutationsColumn,
			mutationScoreColumn,
		]
	}
	
	func test_aCompletelyColumnHasNoWidth() {
		XCTAssertEqual(Table.Column(title: "", rows: []).width, 0)
		
		let emptyColumnWithValues = Table.Column(title: "", rows: [Table.Row(value: "")])
		XCTAssertEqual(emptyColumnWithValues.width, 0)
	}
	
	func test_renderingACompletelyEmptyColumnProducesAnEmptyString() {
		XCTAssertEqual(Table.Column(title: "", rows: []).description, "")
	}
	
	func test_columnsSizeThemselvesToFitTheirLongestContent() {
		XCTAssert(fileColumn.width == 12)
		XCTAssert(numberOfAppliedMutationsColumn.width == 22)
	}
	
	func test_renderingAnEquallySpacedTableWithAPaddingOf3() {
		let expectedTable = """
							File name      # of Applied Mutations   Mutation Score
							---------      ----------------------   --------------
							file 1.swift   1                        60
							file2.swift    2                        0
							file 3.swift   3                        100
							file4.swift    4                        55
							"""
		
		XCTAssert(Table(padding: 3, columns: columns).description.contains(expectedTable))
	}
	
	func test_renderingAnEquallySpacedTableWithAPaddingOf6() {
		let expectedTable = """
							File name         # of Applied Mutations      Mutation Score
							---------         ----------------------      --------------
							file 1.swift      1                           60
							file2.swift       2                           0
							file 3.swift      3                           100
							file4.swift       4                           55
							"""
		
		XCTAssert(Table(padding: 6, columns: columns).description.contains(expectedTable))
	}
	
	func test_rendersTwoDifferentTablesWhenThePaddingSettingIsDifferent() {
		XCTAssertNotEqual(Table(padding: 4, columns: columns).description,
						  Table(padding: 3, columns: columns).description)
	}
}
