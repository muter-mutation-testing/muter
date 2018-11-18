import XCTest
import class Foundation.Bundle

final class ConfigurationParsingTests: XCTestCase {

    func test_parsesAMuterConfigurationFromAJSONFile() {
        
        let muterConfig = FileManager.default.contents(atPath: "\(testDirectory)/fixtures/muter.conf.json")!
        let configuration = try? JSONDecoder().decode(MuterConfiguration.self, from: muterConfig)
        
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
            "platform=iOS Simulator,name=iPhone 6s",
            "test",
            ]
        )
    }
}
