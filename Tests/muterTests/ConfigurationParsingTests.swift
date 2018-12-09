import XCTest
import class Foundation.Bundle

final class ConfigurationParsingTests: XCTestCase {

    func test_parsesAMuterConfigurationFromAJSONFile() {
        let configuration = MuterConfiguration.fromFixture(at: configurationPath)
        
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
            ]
        )
    }
}

extension MuterConfiguration {
    static func fromFixture(at path: String) -> MuterConfiguration? {
        let muterConfig = FileManager.default.contents(atPath: path)!
        return try? JSONDecoder().decode(MuterConfiguration.self, from: muterConfig)
    }
}
