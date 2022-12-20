import XCTest

@testable import muterCore

enum TestingError: String, Error {
    case stub
}

final class CopyProjectToTempDirectoryTests: XCTestCase {
    private let fileManagerSpy = FileManagerSpy()
    private let state = RunCommandState()
    private var result: Result<[RunCommandState.Change], MuterError> = .success([])
    private lazy var sut = CopyProjectToTempDirectory(fileManager: fileManagerSpy)
    
    func test_whenItsAbleToCopyAProjectIntoATempDirectory() {
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.tempDirectoryURL = URL(string: "/tmp/projectName")!
        
        result = sut.run(with: state)
        
        assertThatReturnsTheCopyToTempDirectoryCompleted()
        assertThatCopiesTheProjectToTheTempDirectory()
        assertThatCopiesTheProjectAfterCreatingTheTempDirectory()
    }
    
    func assertThatReturnsTheCopyToTempDirectoryCompleted() {
        guard case .success(let stateChanges) = result else {
            return XCTFail("expected success but got \(String(describing: result))")
        }
        
        XCTAssertEqual(stateChanges, [.copyToTempDirectoryCompleted])
    }
    
    func assertThatCopiesTheProjectToTheTempDirectory() {
        XCTAssertEqual(self.fileManagerSpy.copyPaths.first?.source, "/some/projectName")
        XCTAssertEqual(self.fileManagerSpy.copyPaths.first?.dest, "/tmp/projectName")
        XCTAssertEqual(self.fileManagerSpy.copyPaths.count, 1)
    }
    
    func assertThatCopiesTheProjectAfterCreatingTheTempDirectory() {
        XCTAssertEqual(self.fileManagerSpy.methodCalls, ["copyItem(atPath:toPath:)"])
    }
    
    func test_whenItsUnableToCopyAProjectIntoATempDirectory() {
        fileManagerSpy.errorToThrow = TestingError.stub
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.tempDirectoryURL = URL(string: "/tmp/projectName")!
        
        result = sut.run(with: state)
        
        guard case .failure(.projectCopyFailed(let reason)) = result else {
            XCTFail("expected success but got \(String(describing: result))")
            return
        }
        
        XCTAssertFalse(reason.isEmpty)
    }
}
