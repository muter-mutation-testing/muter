@testable import muterCore
import XCTest
import Yams

final class LoadConfigurationTests: MuterTestCase {
    private lazy var currentDirectory = fixturesDirectory
    private lazy var sut = LoadConfiguration()
    private var state = MutationTestState()

    override func setUp() {
        super.setUp()

        fileManager.currentDirectoryPathToReturn = fixturesDirectory
    }

    func test_loadLJSONConfigurationFromDisk() async throws {
        fileManager.fileExistsToReturn = [false, true]
        fileManager.fileContentsToReturn = loadYAMLConfiguration()

        let result = try await sut.run(with: state)

        let expectedUrl = URL(fileURLWithPath: fixturesDirectory)
        let expectedConfiguration = try XCTUnwrap(MuterConfiguration.fromFixture(
            at: "\(fixturesDirectory)/\(MuterConfiguration.legacyFileNameWithExtension)"
        ))

        XCTAssertEqual(result, [
            .projectDirectoryUrlDiscovered(expectedUrl),
            .configurationParsed(expectedConfiguration),
        ])
    }

    func test_migrationToYaml() async throws {
        fileManager.fileExistsToReturn = [true, false]
        fileManager.fileContentsToReturn = loadJSONConfiguration()

        _ = try await sut.run(with: state)

        XCTAssertTrue(fileManager.methodCalls.contains("removeItem(atPath:)"))
        XCTAssertTrue(fileManager.methodCalls.contains("createFile(atPath:contents:attributes:)"))
        assertConfigurationsEquals(
            fileManager.contents,
            loadYAMLConfiguration()
        )
    }

    private func assertConfigurationsEquals(
        _ actual: Data?,
        _ expected: Data?
    ) {
        guard let actual,
              let expected
        else {
            return XCTFail("Could not assert configurations")
        }

        let actualConfig = try? YAMLDecoder().decode(
            MuterConfiguration.self,
            from: actual
        )
        let expectedConfig = try? YAMLDecoder().decode(
            MuterConfiguration.self,
            from: expected
        )

        XCTAssertEqual(actualConfig, expectedConfig)
    }

    func test_failure() async throws {
        currentDirectory = "/some/projectName"
        fileManager.fileExistsToReturn = [false, false]

        try await assertThrowsMuterError(
            await sut.run(with: state)
        ) { error in
            guard case let .configurationParsingError(reason) = error else {
                XCTFail("Expected configurationParsingError, got \(error)")
                return
            }

            XCTAssertFalse(reason.isEmpty)
        }
    }

    func test_whenUsingXcodeBuildSystem_shouldRequireDestinationInTestArguments() async throws {
        fileManager.fileExistsToReturn = [false, true]
        fileManager.fileContentsToReturn = loadYAMLConfigurationWithoutDestination()

        try await assertThrowsMuterError(
            await sut.run(with: state)
        ) { error in
            guard case let .configurationParsingError(reason) = error else {
                XCTFail("Expected configurationParsingError, got \(error)")
                return
            }

            XCTAssertFalse(reason.isEmpty)
        }
    }

    func test_whenExecutableIsABareCommandName_thenItIsResolvedToItsPathLocation() async throws {
        fileManager.fileExistsToReturn = [false, true]
        fileManager.fileContentsToReturn = MuterConfiguration(
            executable: "swift",
            arguments: ["test"]
        ).asData
        process.stdoutToBeReturned = "/usr/bin/swift\n"

        let result = try await sut.run(with: state)

        // A bare command name is only resolvable by searching PATH. Later steps run the test command
        // from Muter's copy of the project, where `Process` would look for a file literally named
        // "swift" — so the configuration has to carry the absolute path from here on.
        XCTAssertEqual(process.executableURL?.path, "/usr/bin/which")
        XCTAssertEqual(process.arguments, ["swift"])
        XCTAssertEqual(
            result.last,
            .configurationParsed(
                MuterConfiguration(executable: "/usr/bin/swift", arguments: ["test"])
            )
        )
    }

    func test_whenExecutableIsAnAbsolutePath_thenItIsLeftAlone() async throws {
        fileManager.fileExistsToReturn = [false, true]
        fileManager.fileContentsToReturn = MuterConfiguration(
            executable: "/opt/homebrew/bin/swift",
            arguments: ["test"]
        ).asData

        let result = try await sut.run(with: state)

        XCTAssertNil(process.executableURL)
        XCTAssertEqual(
            result.last,
            .configurationParsed(
                MuterConfiguration(executable: "/opt/homebrew/bin/swift", arguments: ["test"])
            )
        )
    }

    func test_whenExecutableIsNotOnPath_thenFailWithAnActionableError() async throws {
        fileManager.fileExistsToReturn = [false, true]
        fileManager.fileContentsToReturn = MuterConfiguration(
            executable: "swiftly",
            arguments: ["test"]
        ).asData

        try await assertThrowsMuterError(
            await sut.run(with: state)
        ) { error in
            // Reported verbatim: the configuration file itself parsed fine, so calling this a parsing
            // error would point the user at the wrong problem.
            guard case let .literal(reason) = error else {
                XCTFail("Expected literal, got \(error)")
                return
            }

            XCTAssertTrue(
                reason.contains("swiftly"),
                "Expected the error to name the executable it couldn't find, got: \(reason)"
            )
            XCTAssertTrue(reason.contains("PATH"), reason)
        }
    }

    func test_loadingConfigurationFromCustomPath() async throws {
        fileManager.fileContentsToReturn = loadYAMLConfiguration()
        fileManager.fileExistsToReturn = [false, true]

        let configurationURL = URL(fileURLWithPath: "/some/custom/path")
        state.runOptions = .make(configurationURL: configurationURL)

        _ = try? await sut.run(with: state)

        XCTAssertEqual(
            fileManager.contentsAtPath,
            ["/some/custom/path/muter.conf.yml"]
        )
    }

    private func loadJSONConfiguration() -> Data? {
        FileManager.default.contents(
            atPath: "\(fixturesDirectory)/\(MuterConfiguration.legacyFileNameWithExtension)"
        )
    }

    private func loadYAMLConfiguration() -> Data? {
        FileManager.default.contents(
            atPath: "\(fixturesDirectory)/\(MuterConfiguration.fileNameWithExtension)"
        )
    }

    private func loadYAMLConfigurationWithoutDestination() -> Data? {
        FileManager.default.contents(
            atPath: "\(fixturesDirectory)/muter.conf.withoutDestination.yml"
        )
    }
}
