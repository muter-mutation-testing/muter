import XCTest
import class Foundation.Bundle

final class FileParserTests: XCTestCase {
    
    func test_loadingANonexistentFileReturnsNil() {
        XCTAssertNil(FileParser.load(path: "I do not exist"))
    }
    
    func test_createsAWorkingDirectoryForMutationTesting() {
        let fileManagerSpy = FileManagerSpy()
        let workingDirectory = FileParser.createWorkingDirectory(in: "~/some/path", fileManager: fileManagerSpy)
        
        XCTAssertEqual(workingDirectory, "~/some/path/muter_tmp")
        XCTAssertEqual(fileManagerSpy.methodCalls, ["createDirectory(atPath:withIntermediateDirectories:attributes:)"])
        XCTAssertEqual(fileManagerSpy.createsIntermediates, [true])
        XCTAssertEqual(fileManagerSpy.paths, ["~/some/path/muter_tmp"])
        
    }
    
    func test_copiesSourceCodeIntoAWorkingDirectory() {
        let workingDirectory = FileParser.createWorkingDirectory(in: testDirectory)
        
        let originalSourceCodePath = "\(testDirectory)/fixtures/sample.swift"
        let originalSourceCode = FileParser.load(path: originalSourceCodePath)
        
        let copiedSourceCodePath = "\(workingDirectory)/sample.swift"
        FileParser.copySourceCode(fromFileAt: originalSourceCodePath,
                                  to: copiedSourceCodePath)
        
        
        let copiedSourceCode = FileParser.load(path: copiedSourceCodePath)
        
        XCTAssertNotNil(originalSourceCode)
        XCTAssertNotNil(copiedSourceCode)
        XCTAssertEqual(originalSourceCode?.description, copiedSourceCode?.description)
        
        removeItems(at: [workingDirectory])
    }
    
    func test_discoversSwiftFilesRecursivelyandReturnsTheResultsAlphabetically() {
        let path = "\(testDirectory)/fixtures/FilesToDiscover"
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
    
    func test_ignoresSourceFilesThatArentSwift() {
        XCTAssertEqual(FileParser.sourceFilesContained(in: "\(testDirectory)/fixtures/FilesToDiscover/Directory4"), [])
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

private extension FileParserTests {
    func removeItems(at paths: [String]) {
        do {
            for path in paths {
                try FileManager.default.removeItem(atPath: path)
            }
        } catch {
            print("❗❗❗ Received error cleaning up after file i/o tests ❗❗❗")
            print(error)
        }
    }
}
