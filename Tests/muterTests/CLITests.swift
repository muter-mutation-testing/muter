import XCTest

@available(OSX 10.13, *)
class CLITests: XCTestCase {
    
    func runningItWithNoArgumentsPrintsAUsageStatement() throws {

        let (output, terminationStatus) = try runMuter(with: [])
        
        XCTAssertEqual(terminationStatus, 1)
        XCTAssertTrue(output.contains("usage"), "expected a usage statement to be printed")
    }
    
    func runningItWithOneArgumentCausesItToMutateTheTestSuiteSpecifiedInTheConfiguration() throws {
        let sourceCodePath = "\(fixturesDirectory)/MuterExampleTestSuite/MuterExampleTestSuite/Module.swift"
        let originalSourceCode = FileUtilities.load(path: sourceCodePath)

        let (output, terminationStatus) = try runMuter(with: [configurationPath])
        
        let afterSourceCode = FileUtilities.load(path: sourceCodePath)
        let workingDirectoryExists = FileManager.default.fileExists(atPath: "\(fixturesDirectory)/MuterExampleTestSuite/muter_tmp", isDirectory: nil)

        XCTAssertEqual(terminationStatus, 0, "Muter returns 0 when it successfully mutates code and causes that code's test suite to fail")
        
        XCTAssert(output.contains("Discovered 3 Swift files"), "Muter reports the number of Swift files it discovers")
        XCTAssertEqual(numberOfDiscoveredFileLists(in: output), 1, "Muter lists the paths of Swift files it discovers")
        XCTAssert(output.contains("Mutation Test Passed"), "Muter causes a test suite to fail, which causes the mutation test to pass")
        XCTAssert(output.contains("Mutation Score of Test Suite: 100%"), "Muter reports a mutation score so an engineer can determine how effective their test suite is at identifying defects or changes to a code base")
        XCTAssert(output.contains("Discovered 3 mutations to introduce in the following files"), "Muter reports how many mutations is able to perform")
        XCTAssertEqual(originalSourceCode!.description, afterSourceCode!.description, "Muter is supposed to clean up after itself by restoring the source code it mutates once it's done")
        XCTAssertFalse(workingDirectoryExists, "Muter is supposed to clean up after itself by deleting the working directory it creates")
    }
}

@available(OSX 10.13, *)
private extension CLITests {
    
    func runMuter(with arguments: [String]) throws -> (output: String, terminationStatus: Int32) {
        let muter = productsDirectory.appendingPathComponent("muter")
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = muter
        process.arguments = arguments
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (
            output: String(data: data, encoding: .utf8) ?? "",
            terminationStatus: process.terminationStatus
        )
    }
    
    func numberOfDiscoveredFileLists(in output: String) -> Int {
        
        let filePathRegex = try! NSRegularExpression(pattern: "Discovered \\d* Swift files:\n(/[^/ ]*)+/?", options: .anchorsMatchLines)
        let entireString = NSRange(location: 0, length: output.count)
        return filePathRegex.numberOfMatches(in: output,
                                             options: .withoutAnchoringBounds,
                                             range: entireString)
    }
}
