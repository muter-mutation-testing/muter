import Quick
import Nimble
@testable import muterCore
import Foundation

class TestSuiteResultParsingSpec: QuickSpec {
    override func spec() {
        describe("TestSuiteResult.from(testLog:)") {
            context("when a test log doesn't contain a failure, runtime error, or build error") {
                it("returns a passed test result") {
                    var contents = loadLogFile(named: "testRunWithoutFailures_withTestSucceededFooter.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.passed))

                    contents = loadLogFile(named: "testRunWithoutFailures_withTestSucceededFooter_buckOutput.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.passed))
                }
            }

            context("when a test log contains a failure") {
                it("returns a failed test result") {
                    var contents = loadLogFile(named: "testRunWithFailures_withoutTestFailedFooter.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.failed))

                    contents = loadLogFile(named: "testRunWithFailures_withTestFailedFooter.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.failed))

                    contents = loadLogFile(named: "testRunWithFailures_withTestFailedFooter_singleTestFailure.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.failed))

                    contents = loadLogFile(named: "testRunWithFailures_withTestFailedFooter_noTestFailureCount.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.failed))

                    contents = loadLogFile(named: "testRunWithFailures_withTestFailedFooter_buckOutput.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.failed))
                }
            }

            context("when a test log contains a fatal error") {
                it("does not return a runtime error if the termination status was 0") {
                    let contents = loadLogFile(named: "runtimeError_fatalError.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.passed))
                }
                it("returns a runtime error if the termination status was not 0") {
                    let contents = loadLogFile(named: "runtimeError_fatalError.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: -127)).to(equal(.runtimeError))
                }

            }

            context("when a test log contains a build error") {
                it("returns a build error") {
                    var contents = loadLogFile(named: "buildError_missingProjectFile.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.buildError))

                    contents = loadLogFile(named: "buildError_runScriptStepFailed.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.buildError))

                    contents = loadLogFile(named: "buildError_invalidSwiftCode.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.buildError))

                    contents = loadLogFile(named: "buildError_withTestFailedFooter.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.buildError))

                    contents = loadLogFile(named: "buildError_buckOutput.log")
                    expect(TestSuiteOutcome.from(testLog: contents, terminationStatus: 0)).to(equal(.buildError))
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
