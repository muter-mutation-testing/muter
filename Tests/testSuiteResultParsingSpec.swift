import Quick
import Nimble
@testable import muterCore
import Foundation

class TestSuiteResultParsingSpec: QuickSpec {
    override func spec() {
        describe("TestSuiteResult.from(testLog:)") {
            context("when a test log doesn't contain a failure, runtime error, or build error") {
                it("returns a passed test result") {
                    let contents = loadLogFile(named: "testRunWithoutFailures_withTestSucceededFooter.log")
                    expect(TestSuiteResult.from(testLog: contents)).to(equal(.passed))
                }
            }

            context("when a test log contains a failure") {
                it("returns a failed test result") {
                    var contents = loadLogFile(named: "testRunWithFailures_withoutTestFailedFooter.log")
                    expect(TestSuiteResult.from(testLog: contents)).to(equal(.failed))

                    contents = loadLogFile(named: "testRunWithFailures_withTestFailedFooter.log")
                    expect(TestSuiteResult.from(testLog: contents)).to(equal(.failed))

                    contents = loadLogFile(named: "testRunWithFailures_withTestFailedFooter_singleTestFailure.log")
                    expect(TestSuiteResult.from(testLog: contents)).to(equal(.failed))
                }
            }

            context("when a test log contains a fatal error") {
                it("returns a runtime error") {
                    let contents = loadLogFile(named: "runtimeError_fatalError.log")
                    expect(TestSuiteResult.from(testLog: contents)).to(equal(.runtimeError))
                }
            }

            context("when a test log contains a build error") {
                it("returns a build error") {
                    var contents = loadLogFile(named: "buildError_missingProjectFile.log")
                    expect(TestSuiteResult.from(testLog: contents)).to(equal(.buildError))

                    contents = loadLogFile(named: "buildError_runScriptStepFailed.log")
                    expect(TestSuiteResult.from(testLog: contents)).to(equal(.buildError))

                    contents = loadLogFile(named: "buildError_invalidSwiftCode.log")
                    expect(TestSuiteResult.from(testLog: contents)).to(equal(.buildError))

                    contents = loadLogFile(named: "buildError_withTestFailedFooter.log")
                    expect(TestSuiteResult.from(testLog: contents)).to(equal(.buildError))
                }
            }
        }
    }
}

private func loadLogFile(named name: String) -> String {
    guard let data = FileManager.default.contents(atPath: "\(TestSuiteResultParsingSpec().fixturesDirectory)/TestLogsForParsing/\(name)"),
        let string = String(data: data, encoding: .utf8) else {
            fatalError("Unable to load a log file named \(name) for testing the XCTest result parser")
    }

    return string
}
