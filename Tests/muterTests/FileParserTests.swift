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
    
    func test_stuff() {
        let originalSourceCode = FileParser.load(path: "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/sample.swift")
        let workingDirectory = FileParser.createWorkingDirectory(in: "/Users/seandorian/Code/Swift/muter/Tests/muterTests")
        
        let newPath = "\(workingDirectory)/sample.swift"
        FileParser.copySourceCode(fromFileAt: "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/sample.swift", to: newPath)
        let copiedSourceCode = FileParser.load(path: newPath)
        
        XCTAssertEqual(originalSourceCode?.description, copiedSourceCode?.description)
        
        removeItems(at: [workingDirectory])
    }
    
    static var allTests = [
        ("\(test_createsAWorkingDirectoryForMutationTesting)", test_createsAWorkingDirectoryForMutationTesting),
        ("\(test_stuff)", test_stuff)
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
