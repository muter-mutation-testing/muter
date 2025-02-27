@testable import muterCore
import XCTest

final class ConfigurationXcodeProjectParsingTests: MuterTestCase {

    func test_withDerivedDataPath() {
        let sut = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: [
                "-project",
                "iOSApp.xcodeproj",
                "-scheme",
                "iOSApp",
                "-destination",
                "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                "-derivedDataPath",
                "foo/bar",
                "test",
            ]
        )

        XCTAssertEqual(
            sut.buildForTestingArguments,
            [
                "-project",
                "iOSApp.xcodeproj",
                "-scheme",
                "iOSApp",
                "-destination",
                "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                "-derivedDataPath",
                "foo/bar",
                "test",
                "clean",
                "build-for-testing",
            ]
        )

        XCTAssertEqual(sut.derivedDataPath, "foo/bar")
    }

    func test_withoutDerivedDataPath() {
        let sut = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: [
                "-project",
                "iOSApp.xcodeproj",
                "-scheme",
                "iOSApp",
                "-destination",
                "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                "test",
            ]
        )

        XCTAssertEqual(
            sut.buildForTestingArguments,
            [
                "-project",
                "iOSApp.xcodeproj",
                "-scheme",
                "iOSApp",
                "-destination",
                "platform=iOS Simulator,name=iPhone SE (3rd generation)",
                "-derivedDataPath",
                "DerivedData",
                "clean",
                "build-for-testing"
            ]
        )

        XCTAssertEqual(sut.derivedDataPath, "DerivedData")
    }
}
