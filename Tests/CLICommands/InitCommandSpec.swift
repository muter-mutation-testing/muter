import Quick
import Nimble
import Foundation
@testable import muterCore

class InitCommandSpec: QuickSpec {
    override func spec() {
        describe("InitCommand") {
            afterEach {
                let workingDirectory = self.rootTestDirectory
                try? FileManager.default.removeItem(atPath: "\(workingDirectory)/\(MuterConfiguration.fileNameWithExtension)")
            }

            it("creates a configuration file named muter.conf.yaml with placeholder values in a specified directory") {
                let workingDirectory = self.rootTestDirectory
                let initCommand = Init(directory: workingDirectory)

                do {
                    try initCommand.run()
                    guard let contents = FileManager.default.contents(atPath: "\(workingDirectory)/muter.conf.yaml"),
                        let _ = try? MuterConfiguration.make(from: contents) else {
                            fail("Expected a valid configuration file to be written")
                            return
                    }
                } catch {
                    fail("Expected a successful result, but got \(error)")
                }
            }
        }
    }
}
