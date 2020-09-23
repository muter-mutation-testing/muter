import Quick
import Nimble
import Foundation
import muterCore

class InitCommandSpec: QuickSpec {
    override func spec() {
        describe("InitCommand") {
            afterEach {
                let workingDirectory = self.rootTestDirectory
                try? FileManager.default.removeItem(atPath: "\(workingDirectory)/muter.conf.json")
            }

            it("creates a configuration file named muter.conf.json with placeholder values in a specified directory") {
                let workingDirectory = self.rootTestDirectory
                let initCommand = Init(directory: workingDirectory)

                do {
                    try initCommand.run()
                    guard let contents = FileManager.default.contents(atPath: "\(workingDirectory)/muter.conf.json"),
                        let _ = try? JSONDecoder().decode(MuterConfiguration.self, from: contents) else {
                            fail("Expected a valid configuration file to be written")
                            return
                    }
                }
                catch {
                    fail("Expected a successful result, but got \(error)")
                }
            }
        }
    }
}

