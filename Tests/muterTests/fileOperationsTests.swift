import XCTest
import class Foundation.Bundle

final class FileOperationsTests: XCTestCase {
    
    func test_generatesAMappingBetweenSwapFilesAndTheirOriginalFilePaths() {
        let paths = ["some/path/to/aFile", "some/path/to/anotherFile"]
        let workingDirectory = "~"
        let expectedMapping = ["some/path/to/aFile": "~/aFile",
                              "some/path/to/anotherFile": "~/anotherFile"]
        
        XCTAssertEqual(swapFilePaths(forFilesAt: paths, using: workingDirectory),
                       expectedMapping)
    }
    
    func test_createsAWorkingDirectoryForMutationTesting() {
        let fileManagerSpy = FileManagerSpy()
        let workingDirectory = createWorkingDirectory(in: "~/some/path", fileManager: fileManagerSpy)
        
        XCTAssertEqual(workingDirectory, "~/some/path/muter_tmp")
        XCTAssertEqual(fileManagerSpy.methodCalls, ["createDirectory(atPath:withIntermediateDirectories:attributes:)"])
        XCTAssertEqual(fileManagerSpy.createsIntermediates, [true])
        XCTAssertEqual(fileManagerSpy.paths, ["~/some/path/muter_tmp"])
        
    }
    
    func test_discoversSwiftFilesRecursivelyandReturnsTheResultsAlphabetically() {
        let path = "\(fixturesDirectory)/FilesToDiscover"
        let discoveredPaths = discoverSourceFiles(inDirectoryAt: path)
        
        XCTAssertEqual(discoveredPaths, [
            "\(path)/Directory1/file3.swift",
            "\(path)/Directory2/Directory3/file6.swift",
            "\(path)/ExampleApp/ExampleAppCode.swift",
            "\(path)/file1.swift",
            "\(path)/file2.swift",
        ])
    }
    
    func test_discoversSwiftFilesUsingACustomBlacklist() {
        let path = "\(fixturesDirectory)/FilesToDiscover"
        let discoveredPaths = discoverSourceFiles(inDirectoryAt: path,
                                                  excludingPathsIn: ["ExampleApp"])
        XCTAssertEqual(discoveredPaths, [
            "\(path)/Directory1/file3.swift",
            "\(path)/Directory2/Directory3/file6.swift",
            "\(path)/file1.swift",
            "\(path)/file2.swift",
        ])
    }
    
    func test_discoversNoSourceFilesWithAnInvalidPath() {
        XCTAssertEqual(discoverSourceFiles(inDirectoryAt: "I don't exist"), [])
    }
    
    func test_ignoresFilesThatArentSwiftFiles() {
        let path = "\(fixturesDirectory)/FilesToDiscover"
        XCTAssertEqual(discoverSourceFiles(inDirectoryAt: "\(path)/Directory4"), [])
        XCTAssertEqual(discoverSourceFiles(inDirectoryAt: "\(path)/Directory2"), [
            "\(path)/Directory2/Directory3/file6.swift"
        ])
    }

    func test_createsSwapFilePaths() {
        let workingDirectory = "/some/path/working_directory"
        
        let firstSwapFilePath = swapFilePath(forFileAt: "/some/path/file.swift", using: workingDirectory)
        XCTAssertEqual(firstSwapFilePath, "/some/path/working_directory/file.swift")
        
        let secondSwapFilePath = swapFilePath(forFileAt: "/some/path/deeper/file.swift", using: workingDirectory)
        XCTAssertEqual(secondSwapFilePath, "/some/path/working_directory/file.swift")
        
        let emptySwapFilePath = swapFilePath(forFileAt: "malformed path that doesn't exist", using: workingDirectory)
        XCTAssertEqual(emptySwapFilePath, "")
    }
}
