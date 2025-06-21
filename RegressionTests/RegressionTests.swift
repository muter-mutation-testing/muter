@testable import muterCore
import SnapshotTesting
import TestingExtensions
import XCTest

final class RegressionTests: XCTestCase {
    func runRegressionTest(
        forFixtureNamed fixtureName: String,
        withResultAt path: FilePath,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) async throws {
        guard let data = FileManager.default.contents(atPath: path) else {
            throw MuterError.literal(reason: "Unable to load a valid Muter test report from \(path)")
        }

        let keysToExclude: (String) -> Bool = {
            $0 == "filePath" || $0 == "utf8Offset" || $0 == "timeElapsed"
        }

        do {
            let testReport = try JSONDecoder().decode(MuterTestReport.self, from: data)
            assertSnapshot(
                of: testReport,
                as: .json(excludingKeysMatching: keysToExclude),
                named: fixtureName,
                file: file,
                testName: testName,
                line: line
            )
            return
        } catch let deserializationError {
            throw MuterError.literal(
                reason: """
                Unable to deserialize a valid Muter test report from \(path)

                \(String(data: data, encoding: .utf8) ?? "no-content")

                \(deserializationError)
                """
            )
        }
    }

    func test_bonMot() async {
        let path = "\(rootTestDirectory)/samples/bonmot_regression_test_output.json"
        do {
            try await runRegressionTest(forFixtureNamed: "bonmot", withResultAt: path)
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_parseCombinator() async {
        let path = "\(rootTestDirectory)/samples/parsercombinator_regression_test_output.json"
        do {
            try await runRegressionTest(forFixtureNamed: "parsercombinator", withResultAt: path)
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_projectWithConcurrency() async {
        let path = "\(rootTestDirectory)/samples/projectwithconcurrency_test_output.json"
        do {
            try await runRegressionTest(forFixtureNamed: "projectwithconcurrency", withResultAt: path)
        } catch {
            XCTFail("\(error)")
        }
    }
}

private extension RegressionTests {
    var rootTestDirectory: String {
        String(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .withoutScheme()
        )
    }
}
