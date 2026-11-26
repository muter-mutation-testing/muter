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
    ) -> Result<Void, MuterError> {
        guard let data = FileManager.default.contents(atPath: path) else {
            return .failure(.literal(reason: "Unable to load a valid Muter test report from \(path)"))
        }

        // The number of failed tests depends on the Xcode version, so the snapshots leave it out.
        let keysToExclude: (String) -> Bool = {
            [
                "filePath", "utf8Offset", "timeElapsed", "numberOfFailedTests", "averageNumberOfFailedTests",
            ].contains($0)
        }

        // A mutant is killed by a failing test or by a crash. Which of the two the test runner reports
        // first depends on the Xcode version, so the snapshot records only that the mutant was killed.
        let killedOutcome: (String, Any) -> Any = { key, value in
            guard key == "testSuiteOutcome",
                  let outcome = value as? String,
                  outcome == TestSuiteOutcome.failed.rawValue || outcome == TestSuiteOutcome.runtimeError.rawValue
            else {
                return value
            }

            return "killed"
        }

        do {
            let testReport = try JSONDecoder().decode(MuterTestReport.self, from: data)
            assertSnapshot(
                of: testReport,
                as: .json(excludingKeysMatching: keysToExclude, transformingValues: killedOutcome),
                named: fixtureName,
                file: file,
                testName: testName,
                line: line
            )
            return .success(())
        } catch let deserializationError {
            return .failure(
                .literal(reason: """
                Unable to deserialize a valid Muter test report from \(path)

                \(String(data: data, encoding: .utf8) ?? "no-content")

                \(deserializationError)
                """)
            )
        }
    }

    func test_bonMot() {
        let path = "\(rootTestDirectory)/samples/bonmot_regression_test_output.json"
        if case let .failure(MuterError.literal(reason: description)) = runRegressionTest(
            forFixtureNamed: "bonmot",
            withResultAt: path
        ) {
            XCTFail(description.description)
        }
    }

    func test_parseCombinator() {
        let path = "\(rootTestDirectory)/samples/parsercombinator_regression_test_output.json"
        if case let .failure(MuterError.literal(reason: description)) = runRegressionTest(
            forFixtureNamed: "parsercombinator",
            withResultAt: path
        ) {
            XCTFail(description)
        }
    }

    func test_projectWithConcurrency() {
        let path = "\(rootTestDirectory)/samples/projectwithconcurrency_test_output.json"
        if case let .failure(MuterError.literal(reason: description)) = runRegressionTest(
            forFixtureNamed: "projectwithconcurrency",
            withResultAt: path
        ) {
            XCTFail(description)
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
