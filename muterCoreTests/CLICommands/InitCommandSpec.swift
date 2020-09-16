import Quick
import Nimble
import Foundation
import Commandant
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
                let initCommand = InitCommand(directory: workingDirectory)
                let noOptions = NoOptions<MuterError>()

                guard case .success = initCommand.run(noOptions) else {
                    fail("Expected a successful result")
                    return
                }

                guard let contents = FileManager.default.contents(atPath: "\(workingDirectory)/muter.conf.json"),
                    let _ = try? JSONDecoder().decode(MuterConfiguration.self, from: contents) else {
                        fail("Expected a valid configuration file to be written")
                        return
                }
            }
        }
    }
}

