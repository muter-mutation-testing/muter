import Quick
import Nimble
import Foundation
@testable import muterCore

class LoadConfigurationSpec: QuickSpec {
    override func spec() {

        var loadConfiguration: LoadConfiguration!
        var result: Result<[RunCommandState.Change], MuterError>!

        describe("the LoadConfiguration step") {
            context("when it's able to load a Muter configuration from disk") {
                beforeEach {
                    loadConfiguration = LoadConfiguration(currentDirectory: self.fixturesDirectory)
                    result = loadConfiguration.run(with: RunCommandState())
                }

                it("returns the parsed configuration") {
                    let expectedUrl = URL(fileURLWithPath: self.fixturesDirectory)
                    let expectedConfiguration = MuterConfiguration.fromFixture(at: "\(self.fixturesDirectory)/muter.conf.json")!

                    guard case .success(let stateChanges) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }

                    expect(stateChanges) == [.projectDirectoryUrlDiscovered(expectedUrl),
                                             .configurationParsed(expectedConfiguration)]
                }
            }

            context("when it's unable to load a Muter configuration from disk") {
                beforeEach {
                    loadConfiguration = LoadConfiguration(currentDirectory: "/some/projectName")
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
}
