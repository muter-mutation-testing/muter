import XCTest

@testable import muterCore

final class LoadConfigurationTests: MuterTestCase {
    private lazy var currentDirectory = fixturesDirectory
    private lazy var sut = LoadConfiguration()
    
    override func setUp() {
        super.setUp()

        fileManager.currentDirectoryPathToReturn = fixturesDirectory
    }

    func test_loadLJSONConfigurationFromDisk() throws {
        fileManager.fileExistsToReturn = [false, true]
        fileManager.fileContentsToReturn = loadYAMLConfiguration()

        let result = try XCTUnwrap(sut.run(with: RunCommandState()).get())

        let expectedUrl = URL(fileURLWithPath: fixturesDirectory)
        let expectedConfiguration = try XCTUnwrap(MuterConfiguration.fromFixture(
            at: "\(self.fixturesDirectory)/\(MuterConfiguration.legacyFileNameWithExtension)"
        ))

        XCTAssertEqual(result, [
            .projectDirectoryUrlDiscovered(expectedUrl),
            .configurationParsed(expectedConfiguration),
        ])
    }

    func test_migrationToYaml() {
        fileManager.fileExistsToReturn = [true, false]
        fileManager.fileContentsToReturn = loadJSONConfiguration()

        _ = sut.run(with: RunCommandState())

        XCTAssertTrue(fileManager.methodCalls.contains("removeItem(atPath:)"))
        XCTAssertTrue(fileManager.methodCalls.contains("createFile(atPath:contents:attributes:)"))
        XCTAssertEqual(fileManager.contents, loadYAMLConfiguration())
    }

    func test_failure() {
        currentDirectory = "/some/projectName"
        fileManager.fileExistsToReturn = [false, false]

        let result = sut.run(with: RunCommandState())

        guard case let .failure(.configurationParsingError(reason: reason)) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        XCTAssertFalse(reason.isEmpty)
    }

    func test_whenUsingXcodeBuildSystem_shouldRequireDestinationInTestArguments() {
        fileManager.fileExistsToReturn = [false, true]
        fileManager.fileContentsToReturn = loadYAMLConfigurationWithoutDestination()

        let result = sut.run(with: RunCommandState())

        guard case let .failure(.configurationParsingError(reason: reason)) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        XCTAssertFalse(reason.isEmpty)
    }

    private func loadJSONConfiguration() -> Data? {
        FileManager.default.contents(
            atPath: "\(self.fixturesDirectory)/\(MuterConfiguration.legacyFileNameWithExtension)"
        )
    }

    private func loadYAMLConfiguration() -> Data? {
        FileManager.default.contents(
            atPath: "\(self.fixturesDirectory)/\(MuterConfiguration.fileNameWithExtension)"
        )
    }

    private func loadYAMLConfigurationWithoutDestination() -> Data? {
        FileManager.default.contents(
            atPath: "\(self.fixturesDirectory)/muter.conf.withoutDestination.yml"
        )
    }
}
