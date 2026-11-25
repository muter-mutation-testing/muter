@testable import muterCore
import XCTest

final class ConfigurationParsingTests: MuterTestCase {
    func test_parse() {
        let configuration = MuterConfiguration.fromFixture(at: "\(fixturesDirectory)/muter.conf.withoutExcludeList.yml")

        XCTAssertEqual(configuration?.excludeFileList, [])
        XCTAssertEqual(configuration?.testCommandExecutable, "/usr/bin/xcodebuild")
        XCTAssertEqual(configuration?.testCommandArguments, [
            "-project",
            "ExampleApp.xcodeproj",
            "-scheme",
            "ExampleApp",
            "-sdk",
            "iphonesimulator",
            "-destination",
            "platform=iOS Simulator,name=iPhone SE (3rd generation)",
            "test",
        ])
    }

    func test_parseExcludeList() {
        let configuration = MuterConfiguration.fromFixture(at: "\(fixturesDirectory)/muter.conf.withExcludeList.yml")

        XCTAssertEqual(configuration?.excludeFileList, ["ExampleApp"])
    }

    func test_parseMutationTestWorkers() throws {
        let yaml = """
        executable: /usr/bin/swift
        arguments: [test]
        mutationTestWorkers: 4
        mutationTestTimeout: 30
        """
        let configuration = try MuterConfiguration(from: Data(yaml.utf8))

        XCTAssertEqual(configuration.mutationTestWorkers, 4)
        XCTAssertEqual(configuration.workerCount, 4)
        XCTAssertEqual(configuration.testSuiteTimeout, 30)
    }

    func test_workerCount_isOneWithoutTheKeyOrOutsideSwiftPM() throws {
        let swift = try MuterConfiguration(from: Data("executable: /usr/bin/swift\narguments: [test]".utf8))
        let xcode = try MuterConfiguration(
            from: Data("executable: /usr/bin/xcodebuild\narguments: [test]\nmutationTestWorkers: 4".utf8)
        )
        let zero = MuterConfiguration(executable: "/usr/bin/swift", mutationTestWorkers: 0)

        XCTAssertEqual(swift.workerCount, 1)
        XCTAssertEqual(xcode.workerCount, 1)
        XCTAssertEqual(zero.workerCount, 1)
    }

    func test_withDefaultTestSuiteTimeout_fillsInOnlyAMissingTimeout() {
        XCTAssertEqual(MuterConfiguration().withDefaultTestSuiteTimeout(12).testSuiteTimeout, 12)
        XCTAssertEqual(
            MuterConfiguration(testSuiteTimeOut: 5, mutationTestWorkers: 3).withDefaultTestSuiteTimeout(12),
            MuterConfiguration(testSuiteTimeOut: 5, mutationTestWorkers: 3)
        )
    }

    func test_buildSystem_defaultsToExecutableBasename() throws {
        let yaml = """
        executable: /usr/bin/xcodebuild
        arguments: [test]
        """
        let configuration = try MuterConfiguration(from: Data(yaml.utf8))

        XCTAssertNil(configuration.explicitBuildSystem)
        XCTAssertEqual(configuration.buildSystem, .xcodebuild)
    }

    func test_explicitBuildSystem_overridesWrapperExecutableName() throws {
        // A wrapper executable whose filename isn't `xcodebuild` would otherwise resolve to `.unknown`;
        // the explicit `buildSystem:` key forces the correct build system.
        let yaml = """
        executable: ./.muter-bin/wrapper.sh
        arguments: [test]
        buildSystem: xcodebuild
        """
        let configuration = try MuterConfiguration(from: Data(yaml.utf8))

        XCTAssertEqual(configuration.explicitBuildSystem, .xcodebuild)
        XCTAssertEqual(configuration.buildSystem, .xcodebuild)
    }
}
