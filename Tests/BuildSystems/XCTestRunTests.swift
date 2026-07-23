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

    func test_updateEnvironmentVariable_createsEnvironmentVariablesWhenAbsent() {
        // A freshly generated .xctestrun target has no EnvironmentVariables dict. The var must still
        // be injected (regression: the old keys.contains guard skipped it → phantom 0% on simulator).
        sut = muterCore.XCTestRun([
            "SomeTestTarget": ["BlueprintName": "SomeTestTarget"] as [String: AnyHashable]
        ])

        let actualPlist = sut.updateEnvironmentVariable(setting: "keyToBeSet")

        let target = actualPlist["SomeTestTarget"] as? [String: AnyHashable]
        let environmentVariables = target?["EnvironmentVariables"] as? [String: AnyHashable]
        XCTAssertEqual(environmentVariables?["keyToBeSet"], isMuterRunningValue)
        XCTAssertEqual(environmentVariables?[isMuterRunningKey], isMuterRunningValue)
    }

    func test_updateEnvironmentVariable_forTestPlan_createsEnvironmentVariablesWhenAbsent() {
        sut = muterCore.XCTestRun([
            "TestConfigurations": [
                ["TestTargets": [["BlueprintName": "SomeTestTarget"] as [String: AnyHashable]]] as [String: AnyHashable]
            ]
        ])

        let actualPlist = sut.updateEnvironmentVariable(setting: "keyToBeSet")

        let testConfigurations = actualPlist["TestConfigurations"] as? [AnyHashable]
        let testConfiguration = testConfigurations?.first as? [String: AnyHashable]
        let testTargets = testConfiguration?["TestTargets"] as? [AnyHashable]
        let testTarget = testTargets?.first as? [String: AnyHashable]
        let environmentVariables = testTarget?["EnvironmentVariables"] as? [String: AnyHashable]

        XCTAssertEqual(environmentVariables?["keyToBeSet"], isMuterRunningValue)
        XCTAssertEqual(environmentVariables?[isMuterRunningKey], isMuterRunningValue)
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
