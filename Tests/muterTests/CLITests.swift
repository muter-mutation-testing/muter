import XCTest

@available(OSX 10.13, *)
class CLITests: XCTestCase {
    
    func test_runningItWithNoArgumentsPrintsAUsageStatement() throws {

        let (output, terminationStatus) = try runMuter(with: [])
        
        XCTAssertEqual(terminationStatus, 1)
        XCTAssertTrue(output.contains("usage"), "expected a usage statement to be printed")
    }
    
    func test_runningItWithOneArgumentCausesItToMutateThatFile() throws {
        let projectPath = "\(testDirectory)/fixtures/MuterExampleTestSuite"
        let arguments = [projectPath]
        let (output, terminationStatus) = try runMuter(with: arguments)

        XCTAssertEqual(terminationStatus, 0, "Muter returns 0 when it successfully mutates code and causes that code's test suite to fail")
//        XCTAssertEqual(numberOfMutatedPathsIn(output), 1)
        XCTAssert(output.contains("XCTAssertTrue failed"), "Muter is supposed to cause a test suite to fail")
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
    
    func numberOfMutatedPathsIn(_ output: String) -> Int {
        let filePathRegex = try! NSRegularExpression(pattern: "(/[^/ ]*)+/?", options: .anchorsMatchLines)
        let entireString = NSRange(location: 0, length: output.count)
        return filePathRegex.numberOfMatches(in: output,
                                             options: .withoutAnchoringBounds,
                                             range: entireString)
    }
}
