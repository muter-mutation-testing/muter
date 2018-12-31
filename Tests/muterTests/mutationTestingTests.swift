@testable import muterCore
import testingCore

import SwiftSyntax
import XCTest

class MutationTestingTests: XCTestCase {
    let expectedSource = SyntaxFactory.makeReturnKeyword()
    var delegateSpy: MutationTestingDelegateSpy!
    var mutationOperatorStub: MutationOperator!

    override func setUp() {
        delegateSpy = MutationTestingDelegateSpy()
        delegateSpy.testSuiteResult = .failed
		mutationOperatorStub = MutationOperator(id: .negateConditionals,
												filePath: "a file path",
												position: .firstPosition,
												source: SyntaxFactory.makeReturnKeyword()) { return $0 }
    }

    func test_performsAMutationTestForEveryMutation() {
		let expectedResults = [
			MutationTestOutcome(testSuiteResult: .failed,
								  appliedMutation: "Negate Conditionals",
								  filePath: "a file path",
								  position: .firstPosition),
			MutationTestOutcome(testSuiteResult: .failed,
								  appliedMutation: "Negate Conditionals",
								  filePath: "a file path",
								  position: .firstPosition),
		]
		
        let actualResults = performMutationTesting(using: [mutationOperatorStub, mutationOperatorStub], delegate: delegateSpy)

        XCTAssertEqual(delegateSpy.methodCalls, ["backupFile(at:)",
												 "writeFile(filePath:contents:)",
                                                 "runTestSuite()",
                                                 "restoreFile(at:)",
                                                 // Second file
                                                 "backupFile(at:)",
												 "writeFile(filePath:contents:)",
                                                 "runTestSuite()",
                                                 "restoreFile(at:)"])
        XCTAssertEqual(delegateSpy.backedUpFilePaths.count, 2)
        XCTAssertEqual(delegateSpy.restoredFilePaths.count, 2)
        XCTAssertEqual(delegateSpy.backedUpFilePaths, delegateSpy.restoredFilePaths)
		
		
		XCTAssertEqual(delegateSpy.mutatedFileContents.first, SyntaxFactory.makeReturnKeyword().description)
		XCTAssertEqual(delegateSpy.mutatedFilePaths.first, "a file path")
		
        XCTAssertEqual(actualResults, expectedResults)
    }

    func test_reportsAMutationScoreForAMutationTestRun() {
        XCTAssertEqual(mutationScore(from: []), -1)

        XCTAssertEqual(mutationScore(from: [.passed]), 0)
        XCTAssertEqual(mutationScore(from: [.failed]), 100)
        
        XCTAssertEqual(mutationScore(from: [.passed, .failed]), 50)
        XCTAssertEqual(mutationScore(from: [.passed, .failed, .failed]), 66)
    }
	
	func test_reportsAMutationScoreForEachFileMutatedFromAMutationTestRun() {
		let expectedMutationScores = [
			"file1.swift": 66,
			"file2.swift": 100,
			"file3.swift": 33,
			"file4.swift": 0
		]

		XCTAssertEqual(mutationScoreOfFiles(from: self.exampleMutationTestResults), expectedMutationScores)
		
	}
}
