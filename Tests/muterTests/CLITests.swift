import XCTest
import SwiftSyntax

@available(OSX 10.13, *)
class CLITests: XCTestCase {
    
    static var originalSourceCode: SourceFileSyntax!
    static var sourceCodePath: String!
    static var output: String!
    
    override static func setUp() {
        sourceCodePath = "\(exampleAppDirectory)/ExampleApp/Module.swift"
        originalSourceCode = sourceCode(fromFileAt: sourceCodePath)!

        let (standardOut, _) = try! runMuter(with: [])
        output = standardOut
    }
    
    override static func tearDown() {
        clearMuterOutputFromLastTestRun()
        
        guard FileManager.default.contents(atPath: muterOutputPath)!.count == 0 else {
            fatalError("The test suite didn't clear out Muter's output from the last test run")
        }
    }
    
    func test_muterReportsTheFilesItDiscovers() {
        XCTAssert(CLITests.output.contains("Discovered 4 Swift files"), "Muter reports the number of Swift files it discovers")
        XCTAssertEqual(numberOfDiscoveredFileLists(in: CLITests.output), 1, "Muter lists the paths of Swift files it discovers")
    }
    
    func test_muterReportsTheMutationsItCanApply() {
        XCTAssert(CLITests.output.contains("Discovered 3 mutations to introduce in the following files"), "Muter reports how many mutations it's able to perform")
    }
    
    func test_muterPerformsAMutationTest() throws {
        XCTAssert(CLITests.output.contains("Mutation Test Passed"), "Muter causes a test suite to fail, which causes the mutation test to pass")
        XCTAssert(CLITests.output.contains("Mutation Test Failed"), "Not every mutation test will pass - it depends on the rigor of the test suite under test.")
    }
    
    func test_muterReportsAMutationScore() {
        XCTAssert(CLITests.output.contains("Mutation Score of Test Suite: 66/100"), "Muter reports a mutation score so an engineer can determine how effective their test suite is at identifying defects or changes to a code base")
    }
    
    func test_muterCleansUpAfterItself()  {
        let afterSourceCode = sourceCode(fromFileAt: CLITests.sourceCodePath)
        let workingDirectoryExists = FileManager.default.fileExists(atPath: "\(CLITests.exampleAppDirectory)/muter_tmp", isDirectory: nil)
        
        XCTAssertNotNil(afterSourceCode, "This file should be available - Muter may have accidentally moved or deleted it")
        XCTAssertEqual(CLITests.originalSourceCode!.description, afterSourceCode!.description, "Muter is supposed to clean up after itself by restoring the source code it mutates once it's done")
        XCTAssertFalse(workingDirectoryExists, "Muter is supposed to clean up after itself by deleting the working directory it creates")
    }
}

@available(OSX 10.13, *)
private extension CLITests {

    static var exampleAppDirectory: String {
        return CLITests().productsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent() // Go up 3 directories
            .appendingPathComponent("ExampleApp") // Go down 1 directory
            .withoutScheme() // Remove the file reference scheme
            .absoluteString
    }
    
    static var muterOutputPath: String { return "\(CLITests().testDirectory)/muters_output.txt" }

    static func clearMuterOutputFromLastTestRun() {
        try! "".write(toFile: muterOutputPath, atomically: true, encoding: .utf8)
    }
    
    static func runMuter(with arguments: [String]) throws -> (output: String, terminationStatus: Int32) {
        let muter = CLITests().productsDirectory.appendingPathComponent("muter")
        let process = Process()
        let fileHandle = FileHandle(forWritingAtPath: muterOutputPath)!
        
        process.executableURL = muter
        process.arguments = arguments
        process.standardOutput = fileHandle
        
        try process.run()
        process.waitUntilExit()
        fileHandle.closeFile()
        
        let data = FileManager.default.contents(atPath: muterOutputPath)!
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
