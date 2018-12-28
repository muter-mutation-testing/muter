@testable import muterCore
import SwiftSyntax
import XCTest

class MutationTestingTests: XCTestCase {
    let expectedSource = SyntaxFactory.makeBlankSourceFile()
    var delegateSpy: MutationTestingDelegateSpy!
    var mutationSpy: SourceCodeMutationSpy!

    override func setUp() {
        delegateSpy = MutationTestingDelegateSpy()
        delegateSpy.testSuiteResult = .failed
        mutationSpy = SourceCodeMutationSpy()
    }

    func test_performsAMutationTestForEveryMutation() {
		let expectedResults = [
			MutationTestOutcome(testSuiteResult: .failed,
								  appliedMutation: "SourceCodeMutationSpy",
								  filePath: "a file path"),
			MutationTestOutcome(testSuiteResult: .failed,
								  appliedMutation: "SourceCodeMutationSpy",
								  filePath: "a file path")
		]
		
        let actualResults = performMutationTesting(using: [mutationSpy, mutationSpy], delegate: delegateSpy)

        XCTAssertEqual(delegateSpy.methodCalls, ["backupFile(at:)",
                                                 "runTestSuite()",
                                                 "restoreFile(at:)",
                                                 // Second file
                                                 "backupFile(at:)",
                                                 "runTestSuite()",
                                                 "restoreFile(at:)"])
        XCTAssertEqual(delegateSpy.backedUpFilePaths.count, 2)
        XCTAssertEqual(delegateSpy.restoredFilePaths.count, 2)
        XCTAssertEqual(delegateSpy.backedUpFilePaths, delegateSpy.restoredFilePaths)
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
