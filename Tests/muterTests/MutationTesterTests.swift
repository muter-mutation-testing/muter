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
        
        let mutationSpy = SourceCodeMutationSpy()
        mutationSpy.canMutate = [true, true]
        
        let filePaths = ["some/path/to/aFile.swift", "some/path/to/anotherFile.swift"]
        
        let mutationTester = MutationTester(filePaths: filePaths,
                                            mutation: mutationSpy,
                                            delegate: delegateSpy)
        
        mutationTester.perform()

        XCTAssertEqual(mutationSpy.mutatedSources.description, [expectedSource, expectedSource].description)
        XCTAssertEqual(delegateSpy.updatedFilePaths, filePaths)
        XCTAssertEqual(delegateSpy.methodCalls, ["sourceFromFile(at:)",
                                                 "backupFile(at:)",
                                                 "writeFile(filePath:contents:)",
                                                 "runTestSuite()",
                                                 "restoreFile(at:)",
                                                 // Second file
                                                 "sourceFromFile(at:)",
                                                 "backupFile(at:)",
                                                 "writeFile(filePath:contents:)",
                                                 "runTestSuite()",
                                                 "restoreFile(at:)"])
    }
    
    func test_doesntRunTestSuiteWhenItEncountersFilesItCantMutate() {
        let delegateSpy = MutationTesterDelegateSpy()
        delegateSpy.sourceFileSyntax = SyntaxFactory.makeBlankSourceFile()
        
        let mutationSpy = SourceCodeMutationSpy()
        mutationSpy.canMutate = [true, false]
        
        let mutationTester = MutationTester(filePaths: ["some/path/to/aFile.swift",
                                                        "some/path/to/aFileThatCantBeMutated.swift"],
                                            mutation: mutationSpy,
                                            delegate: delegateSpy)
        
        mutationTester.perform()
        
        let numberOfTestSuiteRuns = delegateSpy.methodCalls.filter{ $0 == "runTestSuite()" }.count
        XCTAssertEqual(numberOfTestSuiteRuns, 1)
        XCTAssertEqual(mutationSpy.mutatedSources.description, [expectedSource].description)
    }
}
