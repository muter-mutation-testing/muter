import Foundation

enum TestSuiteOutcome: String, Codable, CaseIterable {
    /// Mutant survived
    case passed
    /// Mutant killed
    case failed
    case buildError
    case runtimeError
    case noCoverage
    case timeOut

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
        case .timeOut:
            return "time out"
        }
    }
}

extension TestSuiteOutcome {
    static func from(
        testLog: String,
        terminationStatus: Int32,
        timeOutExecution: TestingExecutionResult? = nil
    ) -> TestSuiteOutcome {
        if timeOutExecution == .timeOut {
            return .timeOut
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
        try! NSRegularExpression(pattern: "with ([1-9]{1}[0-9]{0,}) failure", options: [])
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
