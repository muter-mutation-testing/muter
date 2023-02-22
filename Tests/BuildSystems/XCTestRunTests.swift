import XCTest
import TestingExtensions

@testable import muterCore

final class XCTestRunTests: MuterTestCase {
    private var sut: muterCore.XCTestRun!

    override func setUpWithError() throws {
        try super.setUpWithError()

        sut = try muterCore.XCTestRun(loadPlist())
    }

    func test_updateEnvironmentVariable() {
        let actualPlist = sut.updateEnvironmentVariable(
            setting: "keyToBeSet"
        )

        let project = actualPlist["iOSProjectTests"] as? [String: AnyHashable]
        let environmentVariables = project?["EnvironmentVariables"] as? [String: AnyHashable]
        XCTAssertNotNil(environmentVariables?["keyToBeSet"])
        XCTAssertNotNil(environmentVariables?[isMuterRunningKey])
    }

    private func loadPlist() throws -> [String: AnyHashable] {
        let data = try XCTUnwrap(FileManager.default.contents(atPath: fixturesDirectory + "/BuildForTesting/project.xctestrun"))

        return try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: AnyHashable] ?? [:]
    }
}
