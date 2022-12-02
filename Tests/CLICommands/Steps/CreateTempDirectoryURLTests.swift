import XCTest

@testable import muterCore

final class CreateTempDirectoryURLTests: XCTestCase {
    private var fileManagerSpy = FileManagerSpy()
    private var state = RunCommandState()

    private lazy var sut = CreateTempDirectoryURL(fileManager: fileManagerSpy)
    
    func test_whenItsAbleToCreateATempDirectory() {
        fileManagerSpy.tempDirectory = URL(string: "/tmp")!
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        
        let result = sut.run(with: state)
        
        let assertThatReturnsTheTempDirectoryLocationForMuterToUse = {
            guard case .success(let stateChanges) = result else {
                XCTFail("expected success but got \(String(describing: result))")
                return
            }
            
            XCTAssertEqual(stateChanges, [.tempDirectoryUrlCreated(URL(fileURLWithPath: "/tmp/projectName"))])
        }
        
        let assertThatCreatesATempDirectoryToStoreACopyOfTheCodeUnderTest = {
            XCTAssertEqual(self.fileManagerSpy.searchPathDirectories, [.itemReplacementDirectory])
            XCTAssertEqual(self.fileManagerSpy.domains, [.userDomainMask])
            XCTAssertEqual(self.fileManagerSpy.paths, ["/some/projectName"])
        }
        
        let assertThatCreateTheTempDirectory = {
            XCTAssertEqual(self.fileManagerSpy.methodCalls, ["url(for:in:appropriateFor:create:)"])
        }
        
        assertThatReturnsTheTempDirectoryLocationForMuterToUse()
        assertThatCreatesATempDirectoryToStoreACopyOfTheCodeUnderTest()
        assertThatCreateTheTempDirectory()
    }
    
    func test_whenItsUnableToCreateATempDirectory() {
        fileManagerSpy.tempDirectory = URL(string: "/tmp/")!
        fileManagerSpy.errorToThrow = TestingError.stub

        state.projectDirectoryURL = URL(string: "/some/projectName")!
        
        let result = sut.run(with: state)
        
            guard case .failure(.createTempDirectoryUrlFailed(let reason)) = result else {
                XCTFail("expected success but got \(String(describing: result))")
                return
            }
            
        XCTAssertFalse(reason.isEmpty)
    }
    
    func test_whenItsAbleToCreateASiblingDirectory() {
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.muterConfiguration = .init(mutateFilesInSiblingOfProjectFolder: true)
        
        let result = sut.run(with: state)
        
        guard case .success(let stateChanges) = result else {
            XCTFail("expected success but got \(String(describing: result))")
            return
        }
        
        XCTAssertEqual(stateChanges, [.tempDirectoryUrlCreated(URL(fileURLWithPath: "/some/projectName_mutated"))])
    }
    
    func test_whenItsUnableToCreateASiblingDirectory() {
        fileManagerSpy.errorToThrow = TestingError.stub
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        
        let result = sut.run(with: state)
        
        guard case .failure(.createTempDirectoryUrlFailed(let reason)) = result else {
            XCTFail("expected success but got \(String(describing: result))")
            return
        }
        
        XCTAssertFalse(reason.isEmpty)
    }
}
