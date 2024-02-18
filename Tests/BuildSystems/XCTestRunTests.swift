#if !os(Linux)
@testable import muterCore
import TestingExtensions
import XCTest

final class XCTestRunTests: MuterTestCase {
    private var sut: muterCore.XCTestRun!

    func test_updateEnvironmentVariable() throws {
        sut = try muterCore.XCTestRun(loadPlist(for: "project"))

        let actualPlist = sut.updateEnvironmentVariable(
            setting: "keyToBeSet"
        )

        let project = actualPlist["iOSProjectTests"] as? [String: AnyHashable]
        let environmentVariables = project?["EnvironmentVariables"] as? [String: AnyHashable]
        XCTAssertNotNil(environmentVariables?["keyToBeSet"])
        XCTAssertNotNil(environmentVariables?[isMuterRunningKey])
    }

    func test_updateEnvironmentVariable_forTestPlan() throws {
        sut = try muterCore.XCTestRun(loadPlist(for: "projectWithTestPlan"))

        let actualPlist = sut.updateEnvironmentVariable(
            setting: "keyToBeSet"
        )

        let testConfigurations = actualPlist["TestConfigurations"] as? [AnyHashable]
        let testConfiguration = testConfigurations?.first as? [String: AnyHashable]
        let testTargets = testConfiguration?["TestTargets"] as? [AnyHashable]
        let testTarget = testTargets?.first as? [String: AnyHashable]
        let environmentVariables = testTarget?["EnvironmentVariables"] as? [String: AnyHashable]

        XCTAssertNotNil(environmentVariables?["keyToBeSet"])
        XCTAssertNotNil(environmentVariables?[isMuterRunningKey])
    }

    private func loadPlist(for fileName: String) throws -> [String: AnyHashable] {
        let data = try XCTUnwrap(
            FileManager.default
                .contents(atPath: fixturesDirectory + "/BuildForTesting/\(fileName).xctestrun")
        )

        return try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: AnyHashable] ?? [:]
    }
}
#endif