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
        mutationSpy.filePath = "a/path"
    }

    func test_performsAMutationTestForEveryMutation() {
        let mutationScore = performMutationTesting(using: [mutationSpy, mutationSpy], delegate: delegateSpy)

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
        XCTAssertEqual(mutationScore, 100)
    }

    func test_reportsAMutationScoreForAMutationTestRun() {
        XCTAssertEqual(mutationScore(from: []), -1)

        XCTAssertEqual(mutationScore(from: [.passed]), 0)
        XCTAssertEqual(mutationScore(from: [.failed]), 100)
        XCTAssertEqual(mutationScore(from: [.passed, .failed]), 50)
        XCTAssertEqual(mutationScore(from: [.passed, .failed, .failed]), 66)
    }
}
