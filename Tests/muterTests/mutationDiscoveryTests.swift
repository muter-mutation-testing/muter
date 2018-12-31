@testable import muterCore
import SwiftSyntax
import XCTest

class MutationDiscoveryTests: XCTestCase {
    func test_discoversMutationsThatCanBePerformedOnAFile() {
        let operators = discoverMutationOperators(inFilesAt: ["\(fixturesDirectory)/sampleForDiscoveringMutations.swift"])

		guard operators.count == 4 else {
			XCTFail("Expected to find 4 mutation operators, but got \(operators.count) instead")
			return
		}
		
        XCTAssertEqual(operators[0].filePath, "\(fixturesDirectory)/sampleForDiscoveringMutations.swift")
		XCTAssertEqual(operators[0].position.line, 3)
		XCTAssertEqual(operators[1].filePath, "\(fixturesDirectory)/sampleForDiscoveringMutations.swift")
		XCTAssertEqual(operators[1].position.line, 4)
		XCTAssertEqual(operators[2].filePath, "\(fixturesDirectory)/sampleForDiscoveringMutations.swift")
		XCTAssertEqual(operators[2].position.line, 9)
		XCTAssertEqual(operators[3].filePath, "\(fixturesDirectory)/sampleForDiscoveringMutations.swift")
		XCTAssertEqual(operators[3].position.line, 10)

	}
	

    func test_reportsNoMutationsWhenAFileDoesntHaveAnySourceCodeThatsCompatible() {
        let operators = discoverMutationOperators(inFilesAt: ["\(fixturesDirectory)/sourceWithoutMuteableCode.swift"])
        XCTAssertEqual(operators.count, 0)
    }

    func test_ignoresFilesThatArentSwiftCode() {
        let operators = discoverMutationOperators(inFilesAt: [
            "\(fixturesDirectory)/sampleForDiscoveringMutations.swift",
            "\(fixturesDirectory)/muter.conf.json",
        ])

        let operatorsForNonSwiftCode = operators.exclude { $0.filePath.contains(".swift") }

        XCTAssertEqual(operatorsForNonSwiftCode.count, 0)
		XCTAssertEqual(operators.count, 4)
    }
}
