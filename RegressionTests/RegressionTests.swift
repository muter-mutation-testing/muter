import XCTest
import SnapshotTesting
import TestingExtensions

@testable import muterCore

extension String: Error {}

final class RegressionTests: XCTestCase {
    func runRegressionTest(
        forFixtureNamed fixtureName: String,
        withResultAt path: FilePath,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) -> Result<(), String> {
        guard let data = FileManager.default.contents(atPath: path) else {
            return .failure("Unable to load a valid Muter test report from \(path)")
        }
        
        do {
            let testReport = try JSONDecoder().decode(MuterTestReport.self, from: data)
            assertSnapshot(matching: testReport,
                           as: .json(excludingKeysMatching: { $0 == "filePath" || $0 == "utf8Offset" }),
                           named: fixtureName,
                           file: file,
                           testName: testName,
                           line: line)
            return .success(())
        } catch let deserializationError {
            return .failure("""
                    Unable to deserialize a valid Muter test report from \(path)
                    
                    \(String(data: data, encoding: .utf8) ?? "no-content")
                    
                    \(deserializationError)
                    """)
        }
    }
    
    func test_bonMot() {
        let path = "\(rootTestDirectory)/samples/bonmot_regression_test_output.json"
        if case .failure(let description) = runRegressionTest(forFixtureNamed: "bonmot", withResultAt: path) {
            XCTFail(description)
        }
    }
    
    func test_parseCombinator() {
        let path = "\(rootTestDirectory)/samples/parsercombinator_regression_test_output.json"
        if case .failure(let description) = runRegressionTest(forFixtureNamed: "parsercombinator", withResultAt: path) {
            XCTFail(description)
        }
    }
    
    func test_projectWithConcurrency() {
        let path = "\(rootTestDirectory)/samples/projectwithconcurrency_test_output.json"
        if case .failure(let description) = runRegressionTest(forFixtureNamed: "projectwithconcurrency", withResultAt: path) {
            XCTFail(description)
        }
    }
}

private extension RegressionTests {
    var rootTestDirectory: String {
        return String(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .withoutScheme()
        )
    }
}
