import XCTest
import class Foundation.Bundle

final class FileParserTests: XCTestCase {
    
    let testDirectory = URL(string: #file)!.deletingLastPathComponent().absoluteString
    
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
    
    func test_copyingSourceCodeIntoAWorkingDirectory() {
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
    
    static var allTests = [
        ("\(test_createsAWorkingDirectoryForMutationTesting)", test_createsAWorkingDirectoryForMutationTesting),
        ("\(test_copyingSourceCodeIntoAWorkingDirectory)", test_copyingSourceCodeIntoAWorkingDirectory)
    ]
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
