import XCTest

@testable import muterCore

enum TestingError: String, Error {
    case stub
}

final class CopyProjectToTempDirectoryTests: XCTestCase {
    private let fileManagerSpy = FileManagerSpy()
    private let state = RunCommandState()
    private lazy var sut = CopyProjectToTempDirectory(fileManager: fileManagerSpy)
    
    func test_whenItsAbleToCopyAProjectIntoATempDirectory() {
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.tempDirectoryURL = URL(string: "/tmp/projectName")!
        
        let result = sut.run(with: state)
        
        let assertThatReturnsTheCopyToTempDirectoryCompleted = {
            guard case .success(let stateChanges) = result else {
                return XCTFail("expected success but got \(String(describing: result))")
            }
            
            XCTAssertEqual(stateChanges, [.copyToTempDirectoryCompleted])
        }
        
        let assertThatCopiesTheProjectToTheTempDirectory = {
            XCTAssertEqual(self.fileManagerSpy.copyPaths.first?.source, "/some/projectName")
            XCTAssertEqual(self.fileManagerSpy.copyPaths.first?.dest, "/tmp/projectName")
            XCTAssertEqual(self.fileManagerSpy.copyPaths.count, 1)
        }
        
        let assertThatCopiesTheProjectAfterCreatingTheTempDirectory = {
            XCTAssertEqual(self.fileManagerSpy.methodCalls, ["copyItem(atPath:toPath:)"])
        }
        
        assertThatReturnsTheCopyToTempDirectoryCompleted()
        assertThatCopiesTheProjectToTheTempDirectory()
        assertThatCopiesTheProjectAfterCreatingTheTempDirectory()
    }
    
    func testWhenItsUnableToCopyAProjectIntoATempDirectory() {
        fileManagerSpy.errorToThrow = TestingError.stub
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.tempDirectoryURL = URL(string: "/tmp/projectName")!
        
        let result = sut.run(with: state)
        
        guard case .failure(.projectCopyFailed(let reason)) = result else {
            XCTFail("expected success but got \(String(describing: result))")
            return
        }
        
        XCTAssertFalse(reason.isEmpty)
    }
}
