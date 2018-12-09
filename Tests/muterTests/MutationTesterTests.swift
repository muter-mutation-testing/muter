import XCTest
import SwiftSyntax

class SwapFilePathsTest: XCTestCase {
    func test_generatesAMappingBetweenSwapFilesAndTheirOriginalFilePaths() {
        let filePaths = ["some/path/to/aFile", "some/path/to/anotherFile"]
        let workingDirectory = "~"
        let result = swapFilePaths(for: filePaths, using: workingDirectory)
        XCTAssertEqual(result, ["some/path/to/aFile": "~/aFile",
                                "some/path/to/anotherFile": "~/anotherFile"])
    }
}

class MutationTesterTests: XCTestCase {
    let expectedSource = SyntaxFactory.makeBlankSourceFile()
    var delegateSpy: MutationTesterDelegateSpy!
    var mutationSpy: SourceCodeMutationSpy!
    var mutationTester: MutationTester!
    
    override func setUp() {
        delegateSpy = MutationTesterDelegateSpy()
        delegateSpy.testSuiteResult = .failed
        mutationSpy = SourceCodeMutationSpy()
        mutationSpy.filePath = "a/path"
        mutationTester = MutationTester(mutations: [mutationSpy, mutationSpy],
                                        delegate: delegateSpy)
    }
    
    func test_performsAMutationTestForEveryMutation() {
        mutationTester.perform()
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
    }
    
    func test_reportsAMutationScoreForAMutationTestRun() {
        XCTAssertEqual(mutationScore(from: []), -1)
        
        XCTAssertEqual(mutationScore(from: [.passed]), 0)
        XCTAssertEqual(mutationScore(from: [.failed]), 100)
        XCTAssertEqual(mutationScore(from: [.passed, .failed]), 50)
        XCTAssertEqual(mutationScore(from: [.passed, .failed, .failed]), 66)
    }
}
