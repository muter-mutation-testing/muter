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
