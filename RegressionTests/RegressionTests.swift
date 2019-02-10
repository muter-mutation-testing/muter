import Foundation
import Quick
import Nimble
import SnapshotTesting
@testable import muterCore
import TestingExtensions

@available(OSX 10.13, *)
class RegressionTests: QuickSpec {
    override func spec() {
        describe("muter test report output for bon mot") {
            it("does not contain any changes") {
                let path = "\(self.rootTestDirectory)/bonmot_regression_test_output.json"

                guard let data = FileManager.default.contents(atPath: path),
                    let testReport = try? JSONDecoder().decode(MuterTestReport.self, from: data) else {
                        fail("Unable to load a valid Muter test report from \(path)")
                        return
                }

                assertSnapshot(matching: testReport, as: .json)
            }
        }
    }
}

@available(OSX 10.13, *)
extension RegressionTests {
    var rootTestDirectory: String {
        return String(
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .withoutScheme()
        )
    }
}