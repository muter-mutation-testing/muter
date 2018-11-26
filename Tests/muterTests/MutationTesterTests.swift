import XCTest

class MutationTesterTests: XCTestCase {

    func testExample() {
        
        var filePathsUpdated: [String] = []
        var fileContents: [String] = []
        let writeFileSpy = { (filePath: String, contents: String) in
            filePathsUpdated.append(filePath)
            fileContents.append(contents)
        }
        
        var numberOfTestSuiteRuns = 0
        let runTestSuiteSpy = { (command: String, arguments: [String]) in
            numberOfTestSuiteRuns += 1
        }
        
        let configuration = MuterConfiguration.fromFixture(at: configurationPath)!
        let filePaths = ["\(testDirectory)/fixtures/sample.swift", "\(testDirectory)/fixtures/sample2.swift"]
        let mutationSpy = SourceCodeMutationSpy()
        
        let mutationTester = MutationTester(configuration: configuration,
                                            filePaths: filePaths,
                                            mutation: mutationSpy,
                                            runTestSuite: runTestSuiteSpy,
                                            writeFile: writeFileSpy)
        
        mutationTester.perform()
        
        let expectedSourceOne = FileParser.load(path: "\(testDirectory)/fixtures/sample.swift")!
        let expectedSourceTwo = FileParser.load(path: "\(testDirectory)/fixtures/sample2.swift")!
        XCTAssertEqual(numberOfTestSuiteRuns, 2)
        XCTAssertEqual(mutationSpy.methodCalls, ["mutate(source:)", "mutate(source:)"])
        XCTAssertEqual(mutationSpy.sources.map { $0.description} , [expectedSourceOne.description,
                                                                    expectedSourceTwo.description])
        XCTAssertEqual(filePathsUpdated, ["\(testDirectory)/fixtures/sample.swift",
                                          "\(testDirectory)/fixtures/sample2.swift"])
        XCTAssertEqual(fileContents, [expectedSourceOne.description,
                                      expectedSourceTwo.description])
    }
    
}

