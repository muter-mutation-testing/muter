import XCTest

class MutationTesterTests: XCTestCase {

    func test_performsAMutationTestForEverySourceFile() {
        
        var filePathsUpdated: [String] = []
        var fileContents: [String] = []
        let writeFileSpy = { (filePath: String, contents: String) in
            filePathsUpdated.append(filePath)
            fileContents.append(contents)
        }
        
        var numberOfTestSuiteRuns = 0
        let runTestSuiteSpy = { numberOfTestSuiteRuns += 1 }
        
        let filePaths = ["\(fixturesDirectory)//sample.swift", "\(fixturesDirectory)//sample2.swift"]
        let mutationSpy = SourceCodeMutationSpy()
        mutationSpy.canMutate = [true, true]
        
        let mutationTester = MutationTester(filePaths: filePaths,
                                            mutation: mutationSpy,
                                            runTestSuite: runTestSuiteSpy,
                                            writeFile: writeFileSpy)
        
        mutationTester.perform()
        
        let expectedSourceOne = FileParser.load(path: "\(fixturesDirectory)//sample.swift")!
        let expectedSourceTwo = FileParser.load(path: "\(fixturesDirectory)//sample2.swift")!
        XCTAssertEqual(numberOfTestSuiteRuns, 2)
        XCTAssertEqual(mutationSpy.methodCalls, ["canMutate(source:)", "mutate(source:)", "canMutate(source:)", "mutate(source:)"])
        XCTAssertEqual(mutationSpy.mutatedSources.description, [expectedSourceOne, expectedSourceTwo].description)
        XCTAssertEqual(filePathsUpdated, ["\(fixturesDirectory)//sample.swift",
                                          "\(fixturesDirectory)//sample2.swift"])
        XCTAssertEqual(fileContents, [expectedSourceOne.description,
                                      expectedSourceTwo.description])
    }
    
    func test_doesntRunTestSuiteWhenItEncountersFilesItCantMutate() {
        var filePathsUpdated: [String] = []
        var fileContents: [String] = []
        let writeFileSpy = { (filePath: String, contents: String) in
            filePathsUpdated.append(filePath)
            fileContents.append(contents)
        }
        
        var numberOfTestSuiteRuns = 0
        let runTestSuiteSpy = { numberOfTestSuiteRuns += 1 }

        let filePaths = ["\(fixturesDirectory)//sample.swift", "\(fixturesDirectory)//sourceWithoutConditionalLogic.swift"]
        let mutationSpy = SourceCodeMutationSpy()
        mutationSpy.canMutate = [true, false]
        
        let mutationTester = MutationTester(filePaths: filePaths,
                                            mutation: mutationSpy,
                                            runTestSuite: runTestSuiteSpy,
                                            writeFile: writeFileSpy)
        
        mutationTester.perform()
        
        let expectedSourceOne = FileParser.load(path: "\(fixturesDirectory)//sample.swift")!
        XCTAssertEqual(numberOfTestSuiteRuns, 1)
        XCTAssertEqual(mutationSpy.methodCalls, ["canMutate(source:)", "mutate(source:)", "canMutate(source:)"])
        XCTAssertEqual(mutationSpy.mutatedSources.description , [expectedSourceOne].description)
        XCTAssertEqual(filePathsUpdated, ["\(fixturesDirectory)//sample.swift"])
        XCTAssertEqual(fileContents, [expectedSourceOne.description])
    }
}
