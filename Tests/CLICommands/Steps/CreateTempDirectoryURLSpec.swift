import Quick
import Nimble
import Foundation
@testable import muterCore

class CreateTempDirectoryURLSpec: QuickSpec {
    override func spec() {
        
        var fileManagerSpy: FileManagerSpy!
        var sut: CreateTempDirectoryURL!
        var state: RunCommandState!
        var result: Result<[RunCommandState.Change], MuterError>!
        
        describe("the CreateTempDirectoryURL step to temp folder") {
            context("when it's able to create a temp directory") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    fileManagerSpy.tempDirectory = URL(string: "/tmp")!
                    
                    state = RunCommandState()
                    state.projectDirectoryURL = URL(string: "/some/projectName")!
                    
                    sut = CreateTempDirectoryURL(fileManager: fileManagerSpy)
                    
                    result = sut.run(with: state)
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
                
                it("create the temp directory") {
                    expect(fileManagerSpy.methodCalls).to(equal(["url(for:in:appropriateFor:create:)"]))
                }
            }
            
            context("when it's unable to create a temp directory") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    fileManagerSpy.tempDirectory = URL(string: "/tmp/")!
                    fileManagerSpy.errorToThrow = TestingError.stub
                    
                    state = RunCommandState()
                    state.projectDirectoryURL = URL(string: "/some/projectName")!
                    
                    sut = CreateTempDirectoryURL(fileManager: fileManagerSpy)
                    
                    result = sut.run(with: state)
                }
                
                it("cascades the failure up with a reason that explains why the url creation failed") {
                    guard case .failure(.createTempDirectoryUrlFailed(let reason)) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(reason).notTo(beEmpty())
                }
            }
        }
        
        describe("the CreateTempDirectoryURL step to sibling folder") {
            context("when it's able to create a sibling directory") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    
                    state = RunCommandState()
                    state.projectDirectoryURL = URL(string: "/some/projectName")!
                    state.muterConfiguration = .init(mutateFilesInSiblingOfProjectFolder: true)
                    
                    sut = CreateTempDirectoryURL(fileManager: fileManagerSpy)
                    
                    result = sut.run(with: state)
                }
                
                it("returns the sibling directory location for Muter to use") {
                    guard case .success(let stateChanges) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(stateChanges) == [.tempDirectoryUrlCreated(URL(fileURLWithPath: "/some/projectName_mutated"))]
                }
            }
            
            context("when it's unable to create a sibling directory") {
                beforeEach {
                    fileManagerSpy = FileManagerSpy()
                    fileManagerSpy.errorToThrow = TestingError.stub
                    
                    state = RunCommandState()
                    state.projectDirectoryURL = URL(string: "/some/projectName")!
                    
                    sut = CreateTempDirectoryURL(fileManager: fileManagerSpy)
                    
                    result = sut.run(with: state)
                }
                
                it("cascades the failure up with a reason that explains why the url creation failed") {
                    guard case .failure(.createTempDirectoryUrlFailed(let reason)) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(reason).notTo(beEmpty())
                }
            }
        }
    }
}
