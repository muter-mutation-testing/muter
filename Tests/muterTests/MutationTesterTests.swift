import XCTest

class MutationTesterTests: XCTestCase {
    
    private class MutationTesterDelegateSpy: Spy, MutationTesterDelegate {
        func restoreFile(at path: String) {
            
        }
        
        private(set) var methodCalls: [String] = []
        
        private(set) var filePathsUpdated: [String] = []
        private(set) var fileContents: [String] = []
        private(set) var numberOfTestSuiteRuns = 0

        func writeFile(filePath: String, contents: String) {
            methodCalls.append(#function)
            filePathsUpdated.append(filePath)
            fileContents.append(contents)
        }
        
        func runTestSuite() {
            methodCalls.append(#function)
            numberOfTestSuiteRuns += 1
        }
    }

    func test_performsAMutationTestForEverySourceFile() {
        let delegateSpy = MutationTesterDelegateSpy()
        let filePaths = ["\(fixturesDirectory)/sample.swift", "\(fixturesDirectory)/sample2.swift"]
        let mutationSpy = SourceCodeMutationSpy()
        mutationSpy.canMutate = [true, true]
        
        let mutationTester = MutationTester(filePaths: filePaths,
                                            mutation: mutationSpy,
                                            delegate: delegateSpy)
        
        mutationTester.perform()
        
        let expectedSourceOne = FileParser.load(path: "\(fixturesDirectory)/sample.swift")!
        let expectedSourceTwo = FileParser.load(path: "\(fixturesDirectory)/sample2.swift")!
        XCTAssertEqual(mutationSpy.mutatedSources.description, [expectedSourceOne,
                                                                expectedSourceTwo].description)
        XCTAssertEqual(delegateSpy.filePathsUpdated, ["\(fixturesDirectory)/sample.swift",
                                                      "\(fixturesDirectory)/sample2.swift"])
        XCTAssertEqual(delegateSpy.fileContents, [expectedSourceOne.description,
                                                  expectedSourceTwo.description])
        XCTAssertEqual(delegateSpy.methodCalls, ["writeFile(filePath:contents:)",
                                                 "runTestSuite()",
                                                 "writeFile(filePath:contents:)",
                                                 "runTestSuite()"])
    }
    
    func test_doesntRunTestSuiteWhenItEncountersFilesItCantMutate() {
        let delegateSpy = MutationTesterDelegateSpy()
        let filePaths = ["\(fixturesDirectory)/sample.swift", "\(fixturesDirectory)/sourceWithoutConditionalLogic.swift"]
        let mutationSpy = SourceCodeMutationSpy()
        mutationSpy.canMutate = [true, false]
        
        let mutationTester = MutationTester(filePaths: filePaths,
                                            mutation: mutationSpy,
                                            delegate: delegateSpy)
        
        mutationTester.perform()
        
        let expectedSourceOne = FileParser.load(path: "\(fixturesDirectory)/sample.swift")!
        XCTAssertEqual(delegateSpy.filePathsUpdated, ["\(fixturesDirectory)/sample.swift"])
        XCTAssertEqual(delegateSpy.fileContents, [expectedSourceOne.description])
        XCTAssertEqual(delegateSpy.methodCalls, ["writeFile(filePath:contents:)",
                                                 "runTestSuite()"])
    }
}
