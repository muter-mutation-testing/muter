import Foundation
import Quick
import Nimble
import SnapshotTesting
@testable import muterCore
import TestingExtensions

extension String: Error {}

final class RegressionTests: QuickSpec {

    override func spec() {
        
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
                               as: .json(excludingKeysMatching: { $0 == "filePath" }),
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
        
        describe("muter test report output for BonMot") {
            it("does not contain any changes") {
                let path = "\(self.rootTestDirectory)/samples/bonmot_regression_test_output.json"
                if case .failure(let description) = runRegressionTest(forFixtureNamed: "bonmot", withResultAt: path) {
                    fail(description)
                }
            }
        }
        
        describe("muter test report output for parser combinator") {
            it("does not contain any changes") {
                let path = "\(self.rootTestDirectory)/samples/parsercombinator_regression_test_output.json"
                if case .failure(let description) = runRegressionTest(forFixtureNamed: "parsercombinator", withResultAt: path) {
                    fail(description)
                }
            }
        }
        
        describe("muter test report output for a project with concurrency") {
            it("does not contain any changes") {
                let path = "\(self.rootTestDirectory)/samples/projectwithconcurrency_test_output.json"
                if case .failure(let description) = runRegressionTest(forFixtureNamed: "projectwithconcurrency", withResultAt: path) {
                    fail(description)
                }
            }
        }
    }
}

extension RegressionTests {
    var rootTestDirectory: String {
        return String(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .withoutScheme()
        )
    }
}
