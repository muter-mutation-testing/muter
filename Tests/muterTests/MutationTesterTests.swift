import XCTest

class MutationTesterTests: XCTestCase {
    
    private class MutationTesterInternalsSpy: Spy {
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
        let spy = MutationTesterInternalsSpy()
        let filePaths = ["\(fixturesDirectory)/sample.swift", "\(fixturesDirectory)/sample2.swift"]
        let mutationSpy = SourceCodeMutationSpy()
        mutationSpy.canMutate = [true, true]
        
        let mutationTester = MutationTester(filePaths: filePaths,
                                            mutation: mutationSpy,
                                            runTestSuite: spy.runTestSuite,
                                            writeFile: spy.writeFile)
        
        mutationTester.perform()
        
        let expectedSourceOne = FileParser.load(path: "\(fixturesDirectory)/sample.swift")!
        let expectedSourceTwo = FileParser.load(path: "\(fixturesDirectory)/sample2.swift")!
        XCTAssertEqual(spy.numberOfTestSuiteRuns, 2)
        XCTAssertEqual(mutationSpy.mutatedSources.description, [expectedSourceOne, expectedSourceTwo].description)
        XCTAssertEqual(spy.filePathsUpdated, ["\(fixturesDirectory)/sample.swift",
                                              "\(fixturesDirectory)/sample2.swift"])
        XCTAssertEqual(spy.fileContents, [expectedSourceOne.description,
                                          expectedSourceTwo.description])
        XCTAssertEqual(spy.methodCalls, ["writeFile(filePath:contents:)",
                                         "runTestSuite()",
                                         "writeFile(filePath:contents:)",
                                         "runTestSuite()"])
    }
    
    func test_doesntRunTestSuiteWhenItEncountersFilesItCantMutate() {
        let spy = MutationTesterInternalsSpy()
        let filePaths = ["\(fixturesDirectory)/sample.swift", "\(fixturesDirectory)/sourceWithoutConditionalLogic.swift"]
        let mutationSpy = SourceCodeMutationSpy()
        mutationSpy.canMutate = [true, false]
        
        let mutationTester = MutationTester(filePaths: filePaths,
                                            mutation: mutationSpy,
                                            runTestSuite: spy.runTestSuite,
                                            writeFile: spy.writeFile)
        
        mutationTester.perform()
        
        let expectedSourceOne = FileParser.load(path: "\(fixturesDirectory)/sample.swift")!
        XCTAssertEqual(spy.numberOfTestSuiteRuns, 1)
        XCTAssertEqual(mutationSpy.mutatedSources.description , [expectedSourceOne].description)
        XCTAssertEqual(spy.filePathsUpdated, ["\(fixturesDirectory)/sample.swift"])
        XCTAssertEqual(spy.fileContents, [expectedSourceOne.description])
        XCTAssertEqual(spy.methodCalls, ["writeFile(filePath:contents:)",
                                         "runTestSuite()"])
    }
}
