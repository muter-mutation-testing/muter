import class Foundation.Bundle
@testable import muterCore
import XCTest

final class ConfigurationParsingTests: XCTestCase {
    func test_parsesAMuterConfigurationFromAJSONFile() {
        let configuration = MuterConfiguration.fromFixture(at: "\(fixturesDirectory)/muter.conf.withoutBlacklist.json")

        XCTAssertEqual(configuration?.blacklist, [])
        XCTAssertEqual(configuration?.testCommandExecutable, "/usr/bin/xcodebuild")
        XCTAssertEqual(configuration?.testCommandArguments, [
            "-project",
            "ExampleApp.xcodeproj",
            "-scheme",
            "ExampleApp",
            "-sdk",
            "iphonesimulator",
            "-destination",
            "platform=iOS Simulator,name=iPhone 8",
            "test",
        ])
    }

    func test_parsesAMuterConfigurationWithABlacklist() {
        let configuration = MuterConfiguration.fromFixture(at: "\(fixturesDirectory)/muter.conf.withBlacklist.json")

        XCTAssertEqual(configuration?.blacklist, ["ExampleApp"])
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
