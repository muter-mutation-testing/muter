@testable import muterCore
import Foundation
import Quick
import Nimble

class ConfigurationParsingSpec: QuickSpec {
    override func spec() {
        describe("parsing a configuration file from JSON") {
            it("parses the minimum necessary configuration") {
                let configuration = MuterConfiguration.fromFixture(at: "\(self.fixturesDirectory)/muter.conf.withoutExcludeList.json")

                expect(configuration?.excludeFileList).to(equal([]))
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

                expect(configuration?.excludeFileList).to(equal(["ExampleApp"]))
            }
        }
    }
}
