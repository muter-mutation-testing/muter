@testable import muterCore
import testingCore
import SwiftSyntax
import XCTest

@available(OSX 10.13, *)
class AcceptanceTests: XCTestCase {
    static var originalSourceCode: SourceFileSyntax!
    static var sourceCodePath: String!
    static var output: String!

    override static func setUp() {
        sourceCodePath = "\(exampleAppDirectory)/ExampleApp/Module.swift"
        print("loading code")
        originalSourceCode = sourceCode(fromFileAt: sourceCodePath)!
        print("loaded code")

        output = muterOutput
    }

    func test_muterReportsTheFilesItDiscovers() {
        XCTAssertFalse(AcceptanceTests.output.contains("Discovered 3 Swift files"), "Muter reports the number of Swift files it discovers, taking into account a blacklist which causes it to ignore certain files or directories")
        XCTAssertGreaterThanOrEqual(numberOfDiscoveredFileLists(in: AcceptanceTests.output), 1, "Muter lists the paths of Swift files it discovers")
    }

    func test_muterReportsTheMutationsItCanApply() {
        XCTAssert(AcceptanceTests.output.contains("Discovered 8 mutations to introduce"), "Muter reports how many mutations it's able to perform")
    }

    func test_muterPerformsAMutationTest() throws {
        XCTAssert(AcceptanceTests.output.contains("Mutation Test Passed"), "Muter causes a test suite to fail, which causes the mutation test to pass")
        XCTAssert(AcceptanceTests.output.contains("Mutation Test Failed"), "Not every mutation test will pass - it depends on the rigor of the test suite under test.")
    }

    func test_muterReportsAMutationScore() {
		
		let mutationScoresHeader = """
		--------------------
		Mutation Test Scores
		--------------------
		"""
		
		XCTAssert(AcceptanceTests.output.contains(mutationScoresHeader))
        XCTAssert(AcceptanceTests.output.contains("Mutation Score of Test Suite (higher is better): 25/100"), "Muter reports a mutation score so an engineer can determine how effective their test suite is at identifying defects or changes to a code base")
    }
	
	func test_muterReportstheMutationsItApplied() {
		
		let appliedMutationOperatorsHeader = """
		--------------------------
		Applied Mutation Operators
		--------------------------
		"""
		
		XCTAssert(AcceptanceTests.output.contains(appliedMutationOperatorsHeader))
	}

    func test_muterCleansUpAfterItself() {
        let afterSourceCode = sourceCode(fromFileAt: AcceptanceTests.sourceCodePath)
        let workingDirectoryExists = FileManager.default.fileExists(atPath: "\(AcceptanceTests.exampleAppDirectory)/muter_tmp", isDirectory: nil)

        XCTAssertNotNil(afterSourceCode, "This file should be available - Muter may have accidentally moved or deleted it")
        XCTAssertEqual(AcceptanceTests.originalSourceCode!.description, afterSourceCode!.description, "Muter is supposed to clean up after itself by restoring the source code it mutates once it's done")
        XCTAssertFalse(workingDirectoryExists, "Muter is supposed to clean up after itself by deleting the working directory it creates")
    }
}

@available(OSX 10.13, *)
private extension AcceptanceTests {
    static var exampleAppDirectory: String {
        return AcceptanceTests().productsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent() // Go up 3 directories
            .appendingPathComponent("ExampleApp") // Go down 1 directory
            .withoutScheme() // Remove the file reference scheme
            .absoluteString
    }

    static var muterOutputPath: String { return "\(AcceptanceTests().rootTestDirectory)/acceptanceTests/muters_output.txt" }

    static var muterOutput: String {
        guard let data = FileManager.default.contents(atPath: muterOutputPath),
            let output = String(data: data, encoding: .utf8) else {
            fatalError("Unable to find a valid output file from a prior run of Muter at \(muterOutputPath)")
        }

        return output
    }

    func numberOfDiscoveredFileLists(in output: String) -> Int {
        let filePathRegex = try! NSRegularExpression(pattern: "Discovered \\d* Swift files:\n\n(/[^/ ]*)+/?", options: .anchorsMatchLines)
        let entireString = NSRange(location: 0, length: output.count)
        return filePathRegex.numberOfMatches(in: output,
                                             options: .withoutAnchoringBounds,
                                             range: entireString)
    }
}
