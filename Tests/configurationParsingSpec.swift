@testable import muterCore
import Foundation
import Quick
import Nimble

class ConfigurationParsingSpec: QuickSpec {
    override func spec() {
        describe("parsing a configuration file from JSON") {
            it("parses the minimum necessary configuration") {
                let configuration = MuterConfiguration.fromFixture(at: "\(self.fixturesDirectory)/muter.conf.withoutExcludeList.json")

                expect(configuration?.excludeList).to(equal([]))
                expect(configuration?.testCommandExecutable).to(equal("/usr/bin/xcodebuild"))
                expect(configuration?.testCommandArguments).to(equal([
                    "-project",
                    "ExampleApp.xcodeproj",
                    "-scheme",
                    "ExampleApp",
                    "-sdk",
                    "iphonesimulator",
                    "-destination",
                    "platform=iOS Simulator,name=iPhone 8",
                    "test",
                ]))
            }

            it("parses the excludeList when it's present") {
                let configuration = MuterConfiguration.fromFixture(at: "\(self.fixturesDirectory)/muter.conf.withExcludeList.json")

                expect(configuration?.excludeList).to(equal(["ExampleApp"]))
            }
        }
    }
}

extension MuterConfiguration {
    static func fromFixture(at path: String) -> MuterConfiguration? {

        guard let data = FileManager.default.contents(atPath: path),
            let configuration = try? JSONDecoder().decode(MuterConfiguration.self, from: data) else {
                fatalError("Unable to load a valid Muter configuration file from \(path)")
        }
        return configuration
    }
}
