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

    func test_performsAMutationTestForEverySourceFile() {
        let delegateSpy = MutationTesterDelegateSpy()
        delegateSpy.sourceFileSyntax = expectedSource
        delegateSpy.testSuiteResult = .failed
        
        let mutationSpy = SourceCodeMutationSpy()
//        mutationSpy.canMutate = [true, true]
        
        let filePaths = ["some/path/to/aFile.swift", "some/path/to/anotherFile.swift"]
        
        let mutationTester = MutationTester(mutations: [mutationSpy],
                                            delegate: delegateSpy)
        
        mutationTester.perform()

//        XCTAssertEqual(mutationSpy.mutatedSources.description, [expectedSource, expectedSource].description
        XCTAssertEqual(delegateSpy.methodCalls, [
                                                 "backupFile(at:)",
                                                 
                                                 "runTestSuite()",
                                                 "restoreFile(at:)",
                                                 // Second file
                                                 "backupFile(at:)",
                                                 
                                                 "runTestSuite()",
                                                 "restoreFile(at:)"])
    }
    
    func test_doesntRunTestSuiteWhenItEncountersFilesItCantMutate() {
        let delegateSpy = MutationTesterDelegateSpy()
        delegateSpy.sourceFileSyntax = SyntaxFactory.makeBlankSourceFile()
        delegateSpy.testSuiteResult = .failed

        let mutationSpy = SourceCodeMutationSpy()

        let mutationTester = MutationTester(mutations: [mutationSpy],
                                            delegate: delegateSpy)
        
        mutationTester.perform()
        
        let numberOfTestSuiteRuns = delegateSpy.methodCalls.filter{ $0 == "runTestSuite()" }.count
        XCTAssertEqual(numberOfTestSuiteRuns, 1)
    }
    
    func test_reportsAMutationScoreForAMutationTestRun() {
        let delegateSpy = MutationTesterDelegateSpy()
        delegateSpy.sourceFileSyntax = expectedSource
        delegateSpy.testSuiteResult = .failed
        
        let mutationSpy = SourceCodeMutationSpy()
        
        let mutationTester = MutationTester(mutations: [mutationSpy],
                                            delegate: delegateSpy)
        
        XCTAssertEqual(mutationTester.mutationScore, -1)
        
        mutationTester.perform()
        
        XCTAssertEqual(mutationTester.mutationScore, 100)
    }
}
