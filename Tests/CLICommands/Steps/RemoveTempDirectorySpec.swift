import Quick
import Nimble
import Foundation
@testable import muterCore

enum RemoveTempDirectorySpecError: String, Error {
    case stub
}

class RemoveTempDirectorySpec: QuickSpec {
    override func spec() {
        
        var fileManagerSpy: FileManagerSpy!
        var removeTempDirectory: RemoveTempDirectory!
        var state: RunCommandState!
        var result: Result<[RunCommandState.Change], MuterError>!
        
        describe("the RemoveTempDirectory step") {
            context("when it's able to remove a temp directory") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    
                    state = RunCommandState()
                    state.tempDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")
                    
                    removeTempDirectory = RemoveTempDirectory(fileManager: fileManagerSpy)
                    
                    result = removeTempDirectory.run(with: state)
                }
                
                it("returns the tempDirectoryRemoved change") {
                    guard case .success(let stateChanges) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(stateChanges) == [.tempDirectoryRemoved]
                }
                
                it("remove the project from the temp directory") {
                    expect(fileManagerSpy.paths.first).to(equal("/some/projectName_mutated"))
                    expect(fileManagerSpy.paths).to(haveCount(1))
                    expect(fileManagerSpy.methodCalls).to(equal(["removeItem(atPath:)"]))
                }
            }
            
            context("when it's unable to remove a temp directory") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    fileManagerSpy.errorToThrow = RemoveTempDirectorySpecError.stub
                    
                    state = RunCommandState()
                    state.tempDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")

                    removeTempDirectory = RemoveTempDirectory(fileManager: fileManagerSpy)
                    
                    result = removeTempDirectory.run(with: state)
                }
                
                it("throws the MuterError.removeTempDirectoryFailed error") {
                    guard case .failure(.removeTempDirectoryFailed(let reason)) = result! else {
                        fail("expected failure but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(reason).notTo(beEmpty())
                }
            }
            
            context("when it run as a trap") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    
                    state = RunCommandState()
                    state.tempDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")
                    
                    removeTempDirectory = RemoveTempDirectory(fileManager: fileManagerSpy)
                    
                    (removeTempDirectory as RunCommandTrap).run(with: state)
                }
                
                it("remove the project from the temp directory") {
                    expect(fileManagerSpy.paths.first).to(equal("/some/projectName_mutated"))
                    expect(fileManagerSpy.paths).to(haveCount(1))
                    expect(fileManagerSpy.methodCalls).to(equal(["removeItem(atPath:)"]))
                }
            }
        }
    }
}

