@testable import muterCore
import SwiftSyntax
import XCTest

class MutationDiscoveryTests: XCTestCase {
    func test_discoversMutationsThatCanBePerformedOnAFile() {
        let expectedSource = sourceCode(fromFileAt: "\(fixturesDirectory)/sampleForDiscoveringMutations.swift")!
        let mutations = discoverMutations(inFilesAt: ["\(fixturesDirectory)/sampleForDiscoveringMutations.swift"])

        XCTAssertEqual(mutations.count, 2)
        XCTAssertEqual(mutations.first?.filePath, "\(fixturesDirectory)/sampleForDiscoveringMutations.swift")
        XCTAssertEqual(mutations.first?.sourceCode.description, expectedSource.description)
    }

    func test_reportsNoMutationsWhenAFileDoesntHaveAnySourceCodeThatsCompatible() {
        let mutations = discoverMutations(inFilesAt: ["\(fixturesDirectory)/sourceWithoutConditionalLogic.swift"])
        XCTAssertEqual(mutations.count, 0)
    }

    func test_ignoresFilesThatArentSwiftCode() {
        let configurationFilePath = "\(fixturesDirectory)/muter.conf.swift"
        let mutations = discoverMutations(inFilesAt: [
            "\(fixturesDirectory)/sample.swift",
            configurationFilePath,
        ])

        let mutationsForNonSwiftCode = mutations.filter {
            $0.filePath == configurationFilePath
        }

        XCTAssertEqual(mutationsForNonSwiftCode.count, 0)
    }
}
