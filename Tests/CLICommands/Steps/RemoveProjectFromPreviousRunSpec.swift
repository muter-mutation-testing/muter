import Quick
import Nimble
import Foundation
@testable import muterCore

enum RemoveTempDirectorySpecError: String, Error {
    case stub
}

class RemoveProjectFromPreviousRunSpec: QuickSpec {
    override func spec() {
        
        var fileManagerSpy: FileManagerSpy!
        var sut: RemoveProjectFromPreviousRun!
        var state: RunCommandState!
        var result: Result<[RunCommandState.Change], MuterError>!
        
        describe("the RemoveTempDirectory step") {
            context("when it's able to remove a temp directory") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    fileManagerSpy.fileExistsToReturn = [true]
                    
                    state = RunCommandState()
                    state.tempDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")
                    
                    sut = RemoveProjectFromPreviousRun(fileManager: fileManagerSpy)
                    
                    result = sut.run(with: state)
                }
                
                it("returns the removeProjectFromPreviousRunCompleted") {
                    guard case .success(let stateChanges) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(stateChanges) == [.removeProjectFromPreviousRunCompleted]
                }
                
                it("remove the project from the temp directory") {
                    expect(fileManagerSpy.paths.first).to(equal("/some/projectName_mutated"))
                    expect(fileManagerSpy.paths).to(haveCount(1))
                    expect(fileManagerSpy.methodCalls).to(equal(["fileExists(atPath:)", "removeItem(atPath:)"]))
                }
            }
            
            context("when it's unable to remove a temp directory") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    fileManagerSpy.errorToThrow = RemoveTempDirectorySpecError.stub
                    fileManagerSpy.fileExistsToReturn = [true]
                    
                    state = RunCommandState()
                    state.tempDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")

                    sut = RemoveProjectFromPreviousRun(fileManager: fileManagerSpy)
                    
                    result = sut.run(with: state)
                }
                
                it("throws the MuterError.removeProjectFromPreviousRunFailed error") {
                    guard case .failure(.removeProjectFromPreviousRunFailed(let reason)) = result! else {
                        fail("expected failure but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(reason).notTo(beEmpty())
                }
            }
            
            context("when file does not exist") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    fileManagerSpy.errorToThrow = RemoveTempDirectorySpecError.stub
                    fileManagerSpy.fileExistsToReturn = [false]
                    
                    state = RunCommandState()
                    state.tempDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")

                    sut = RemoveProjectFromPreviousRun(fileManager: fileManagerSpy)
                    
                    result = sut.run(with: state)
                }
                
                it("returns the removeProjectFromPreviousRunSkipped") {
                    guard case .success(let stateChanges) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(stateChanges) == [.removeProjectFromPreviousRunSkipped]
                }
            }
        }
    }
}

