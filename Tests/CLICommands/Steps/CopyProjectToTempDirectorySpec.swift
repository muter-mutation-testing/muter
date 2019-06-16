import Quick
import Nimble
import Foundation
@testable import muterCore

enum TestingError: String, Error {
    case stub
}

class CopyProjectToTempDirectorySpec: QuickSpec {
    override func spec() {
        
        var fileManagerSpy: FileManagerSpy!
        var copyProjectToTempDirectory: CopyProjectToTempDirectory!
        var state: RunCommandState!
        var result: Result<[RunCommandState.Change], MuterError>!
        
        describe("the CopyProjectToTempDirectory step") {
            context("when it's able to copy a project into a temp directory") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    fileManagerSpy.tempDirectory = URL(string: "/tmp/")!
                    
                    state = RunCommandState()
                    state.projectDirectoryURL = URL(string: "/some/projectName")!
                    
                    copyProjectToTempDirectory = CopyProjectToTempDirectory(fileManager: fileManagerSpy)
                    
                    result = copyProjectToTempDirectory.run(with: state)
                }
                
                it("returns the temp directory location for Muter to use") {
                    guard case .success(let stateChanges) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(stateChanges) == [.tempDirectoryUrlCreated(URL(fileURLWithPath: "/tmp/projectName"))]
                }
                
                it("creates a temp directory to store a copy of the code under test") {
                    expect(fileManagerSpy.searchPathDirectories).to(equal([.itemReplacementDirectory]))
                    expect(fileManagerSpy.domains).to(equal([.userDomainMask]))
                    expect(fileManagerSpy.paths).to(equal(["/some/projectName"]))
                }
                
                it("copies the project to the temp directory") {
                    expect(fileManagerSpy.copyPaths.first?.source).to(equal("/some/projectName"))
                    expect(fileManagerSpy.copyPaths.first?.dest).to(equal("/tmp/projectName"))
                    expect(fileManagerSpy.copyPaths).to(haveCount(1))
                }
                
                it("copies the project after creating the temp directory") {
                    expect(fileManagerSpy.methodCalls).to(equal(["url(for:in:appropriateFor:create:)",
                                                                 "copyItem(atPath:toPath:)"]))
                }
            }
            
            context("when it's unable to copy a project into a temp directory") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    fileManagerSpy.tempDirectory = URL(string: "/tmp/")!
                    fileManagerSpy.errorToThrow = TestingError.stub
                    
                    state = RunCommandState()
                    state.projectDirectoryURL = URL(string: "/some/projectName")!
                    
                    copyProjectToTempDirectory = CopyProjectToTempDirectory(fileManager: fileManagerSpy)
                    
                    result = copyProjectToTempDirectory.run(with: state)
                }
                
                it("cascades the failure up with a reason that explains why the project copy failed") {
                    guard case .failure(.projectCopyFailed(let reason)) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(reason).notTo(beEmpty())
                }
            }
        }
    }
}
