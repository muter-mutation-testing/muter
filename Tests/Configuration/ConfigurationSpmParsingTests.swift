@testable import muterCore
import XCTest

final class ConfigurationSpmParsingTests: MuterTestCase {
    func test_withCustomBuildPath() {
        let sut = MuterConfiguration(
            executable: "/path/to/swift",
            arguments: [
                "--build-path",
                "foo/bar",
                "test"
            ]
        )

        XCTAssertEqual(
            sut.buildForTestingArguments,
            [
                "--build-path",
                "foo/bar",
                "test"
            ]
        )

        XCTAssertEqual(sut.buildPath, "foo/bar")
    }
}
