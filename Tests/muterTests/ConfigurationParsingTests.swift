import XCTest
import class Foundation.Bundle

final class ConfigurationParsingTests: XCTestCase {

    func test_parsesAMuterConfigurationFromAJSONFile() {
        let configuration = MuterConfiguration.fromFixture(at: configurationPath)
        
        XCTAssertEqual(configuration?.projectDirectory, "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/MuterExampleTestSuite")
        
        XCTAssertEqual(configuration?.testCommandExecutable, "/usr/bin/xcodebuild")
        XCTAssertEqual(configuration?.testCommandArguments, [
            "-verbose",
            "-project",
            "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/MuterExampleTestSuite/MuterExampleTestSuite.xcodeproj",
            "-scheme",
            "MuterExampleTestSuite",
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
