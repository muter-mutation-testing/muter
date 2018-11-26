import XCTest
import class Foundation.Bundle

final class FileParserTests: XCTestCase {
    func test_createsAWorkingDirectoryForMutationTesting() {
        let fileManagerSpy = FileManagerSpy()
        let workingDirectory = FileParser.createWorkingDirectory(in: "~/some/path", fileManager: fileManagerSpy)
        
        XCTAssertEqual(workingDirectory, "~/some/path/muter_tmp")
        XCTAssertEqual(fileManagerSpy.methodCalls, ["createDirectory(atPath:withIntermediateDirectories:attributes:)"])
        XCTAssertEqual(fileManagerSpy.createsIntermediates, [true])
        XCTAssertEqual(fileManagerSpy.paths, ["~/some/path/muter_tmp"])
        
    }
    
    func test_discoversSwiftFilesRecursivelyandReturnsTheResultsAlphabetically() {
        let path = "\(fixturesDirectory)/FilesToDiscover"
        let discoveredPaths = FileParser.sourceFilesContained(in:
            path)
        XCTAssertEqual(discoveredPaths, [
            "\(path)/Directory1/file3.swift",
            "\(path)/Directory2/Directory3/file6.swift",
            "\(path)/file1.swift",
            "\(path)/file2.swift",
            ]
        )
    }
    
    func test_discoversNoSourceFilesWithAnInvalidPath() {
        XCTAssertEqual(FileParser.sourceFilesContained(in: "I don't exist"), [])
    }
    
    func test_ignoresFilesThatArentSwiftFiles() {
        let path = "\(fixturesDirectory)/FilesToDiscover"
        XCTAssertEqual(FileParser.sourceFilesContained(in: "\(path)/Directory4"), [])
        XCTAssertEqual(FileParser.sourceFilesContained(in: "\(path)/Directory2"), [
            "\(path)/Directory2/Directory3/file6.swift"
        ])
    }

    func test_createsSwapFilePaths() {
        let workingDirectory = "/some/path/working_directory"
        
        let firstSwapFilePath = FileParser.swapFilePath(forFileAt: "/some/path/file.swift", using: workingDirectory)
        XCTAssertEqual(firstSwapFilePath, "/some/path/working_directory/file.swift")
        
        let secondSwapFilePath = FileParser.swapFilePath(forFileAt: "/some/path/deeper/file.swift", using: workingDirectory)
        XCTAssertEqual(secondSwapFilePath, "/some/path/working_directory/file.swift")
        
        let emptySwapFilePath = FileParser.swapFilePath(forFileAt: "malformed path that doesn't exist", using: workingDirectory)
        XCTAssertEqual(emptySwapFilePath, "")
    }
}
