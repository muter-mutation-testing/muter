import Quick
import Nimble
import Foundation
@testable import muterCore

class LoadConfigurationSpec: QuickSpec {
    override func spec() {
        
        var fileManager: FileManagerSpy!
        var loadConfiguration: LoadConfiguration!
        var result: Result<[RunCommandState.Change], MuterError>!
        
        describe("the LoadConfiguration step") {
            context("when it's able to load a Muter configuration from disk") {
                beforeEach {
                    fileManager = FileManagerSpy()
                    fileManager.fileExistsToReturn = [false, true]
                    fileManager.fileContentsToReturn = self.loadYAMLConfiguration()

                    loadConfiguration = LoadConfiguration(
                        fileManager: fileManager,
                        currentDirectory: self.fixturesDirectory
                    )
                    result = loadConfiguration.run(with: RunCommandState())
                }

                it("returns the parsed configuration") {
                    let expectedUrl = URL(fileURLWithPath: self.fixturesDirectory)
                    let expectedConfiguration = MuterConfiguration.fromFixture(
                        at: "\(self.fixturesDirectory)/\(MuterConfiguration.legacyFileNameWithExtension)"
                    )!

                    guard case .success(let stateChanges) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(stateChanges) == [.projectDirectoryUrlDiscovered(expectedUrl),
                                             .configurationParsed(expectedConfiguration),]
                }
            }
            
            context("when it's able to load a legacy Muter configuration from disk") {
                beforeEach {
                    fileManager = FileManagerSpy()
                    fileManager.fileExistsToReturn = [true, false]
                    fileManager.fileContentsToReturn = self.loadJSONConfiguration()

                    loadConfiguration = LoadConfiguration(
                        fileManager: fileManager,
                        currentDirectory: self.fixturesDirectory
                    )
                    result = loadConfiguration.run(with: RunCommandState())
                }

                it("migrates to YAML") {
                    expect(fileManager.methodCalls).to(contain("removeItem(atPath:)"))
                    expect(fileManager.methodCalls).to(contain("createFile(atPath:contents:attributes:)"))
                    expect(fileManager.contents).to(equal(self.loadYAMLConfiguration()))
                }
            }
            
            context("when it's unable to load a Muter configuration from disk") {
                beforeEach {
                    fileManager = FileManagerSpy()
                    fileManager.fileExistsToReturn = [false, false]

                    loadConfiguration = LoadConfiguration(
                        fileManager: fileManager,
                        currentDirectory: "/some/projectName"
                    )
                    result = loadConfiguration.run(with: RunCommandState())
                }
                
                it("cascades the failure up with a reason that explains why it failed to load a configuration") {
                    guard case .failure(.configurationParsingError) = result! else {
                        fail("expected a configurationError but got \(String(describing: result!))")
                        return
                    }
                }
            }
        }
    }
    
    private func loadJSONConfiguration() -> Data? {
        FileManager.default.contents(
            atPath: "\(self.fixturesDirectory)/\(MuterConfiguration.legacyFileNameWithExtension)"
        )
    }
    
    private func loadYAMLConfiguration() -> Data? {
        FileManager.default.contents(
            atPath: "\(self.fixturesDirectory)/\(MuterConfiguration.fileNameWithExtension)"
        )
    }
}
