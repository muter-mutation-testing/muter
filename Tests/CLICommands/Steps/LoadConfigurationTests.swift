@testable import muterCore
import XCTest

final class LoadConfigurationTests: MuterTestCase {
    private lazy var currentDirectory = fixturesDirectory
    private lazy var sut = LoadConfiguration()

    override func setUp() {
        super.setUp()

        fileManager.currentDirectoryPathToReturn = fixturesDirectory
    }

    func test_loadLJSONConfigurationFromDisk() async throws {
        fileManager.fileExistsToReturn = [false, true]
        fileManager.fileContentsToReturn = loadYAMLConfiguration()

        let result = try await sut.run(with: RunCommandState())

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

        _ = try await sut.run(with: RunCommandState())

        XCTAssertTrue(fileManager.methodCalls.contains("removeItem(atPath:)"))
        XCTAssertTrue(fileManager.methodCalls.contains("createFile(atPath:contents:attributes:)"))
        XCTAssertEqual(fileManager.contents, loadYAMLConfiguration())
    }

    func test_failure() async throws {
        currentDirectory = "/some/projectName"
        fileManager.fileExistsToReturn = [false, false]

        try await assertThrowsMuterError(
            await sut.run(with: RunCommandState())
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
            await sut.run(with: RunCommandState())
        ) { error in
            guard case let .configurationParsingError(reason) = error else {
                XCTFail("Expected configurationParsingError, got \(error)")
                return
            }

            XCTAssertFalse(reason.isEmpty)
        }
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
