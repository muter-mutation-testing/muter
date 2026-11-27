import Foundation

enum TestSuiteOutcome: String, Codable, CaseIterable {
    /// Mutant survived
    case passed
    /// Mutant killed
    case failed
    case buildError
    case runtimeError
    case noCoverage
    case timeout
    /// A `muter:disable` comment turned the mutant off, so Muter did not test it.
    case ignored

    var asMutationTestOutcome: String {
        switch self {
        case .passed:
            return "mutant survived"
        case .failed:
            return "mutant killed (test failure)"
        case .buildError:
            return "build error"
        case .runtimeError:
            return "mutant killed (runtime error)"
        case .noCoverage:
            return "skipped (no coverage)"
        case .timeout:
            return "mutant killed (time out)"
        case .ignored:
            return "ignored (muter:disable)"
        }
    }

    /// The tests detected the mutant: a test failed, the tests crashed, or they did not finish in
    /// time. A mutant that makes the code loop forever is detected, like in Stryker and PIT.
    var isKilled: Bool {
        self == .failed || self == .runtimeError || self == .timeout
    }
}

extension TestSuiteOutcome {
    static func from(
        testLog: String,
        terminationStatus: Int32,
        timeoutExecution: TestingExecutionResult? = nil
    ) -> TestSuiteOutcome {
        if timeoutExecution == .timeout {
            return outcomeOfTimedOutRun(testLog)
        }

        if logContainsBuildError(testLog) {
            return .buildError
        } else if logContainsTestFailure(testLog) {
            return .failed
        } else if !terminationStatusIsSuccess(terminationStatus) {
            return .runtimeError
        }

        return .passed
    }

    /// A run can hit the time limit after the mutant was already killed: xcodebuild waits a long time
    /// before it restarts the tests after a crash, and the default limit is only a few baseline runs.
    /// Such a mutant is killed, not timed out. Only a run whose log shows no failure and no crash
    /// counts as a timeout.
    private static func outcomeOfTimedOutRun(_ testLog: String) -> TestSuiteOutcome {
        if logContainsTestFailure(testLog) {
            return .failed
        } else if logContainsCrash(testLog) {
            return .runtimeError
        }

        return .timeout
    }

    private static func logContainsCrash(_ testLog: String) -> Bool {
        testLog.contains("Fatal error:") ||
            testLog.contains("Exited with unexpected signal code")
    }

    private static func logContainsTestFailure(_ testLog: String) -> Bool {
        let entireTestLog = NSRange(testLog.startIndex..., in: testLog)
        let numberOfFailureMessages = testFailureRegEx.numberOfMatches(in: testLog, options: [], range: entireTestLog)
        return numberOfFailureMessages > 0 ||
            testLog.contains(testFailedMessage(from: .xcodebuild)) ||
            testLog.contains(testFailedMessage(from: .buck))
    }

    private static func testFailedMessage(from testingBuildSystem: TestingBuildSystem) -> String {
        switch testingBuildSystem {
        case .xcodebuild: return "** TEST FAILED **"
        case .buck: return "TESTS FAILED: "
        case .swift: return " failures "
        }
    }

    private static var testFailureRegEx: NSRegularExpression {
        NSRegularExpression.regexWithPattern(#"test\(s\)? failed|with ([1-9][0-9]*) (failure|issue)|with ([1-9][0-9]*) tests? failed"#)
    }

    private static func terminationStatusIsSuccess(_ terminationStatus: Int32) -> Bool {
        terminationStatus == 0
    }

    private static func logContainsBuildError(_ testLog: String) -> Bool {
        testLog.contains("xcodebuild: error:") ||
            testLog.contains("error: terminated") ||
            testLog.contains("failed with a nonzero exit code") ||
            testLog.contains("Testing cancelled because the build failed") ||
            testLog.contains("Command failed with exit code 1.")
    }
}

private enum TestingBuildSystem {
    case xcodebuild
    case buck
    case swift
}
