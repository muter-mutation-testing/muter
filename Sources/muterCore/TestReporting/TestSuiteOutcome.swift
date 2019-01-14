import Foundation

public enum TestSuiteOutcome: String, Codable {
    case passed
    case failed
    case buildError
    case runtimeError

    var asMutationTestOutcome: String {
        switch self {
        case .passed:
            return "failed"
        case .failed:
            return "passed"
        case .buildError:
            return "build error"
        case .runtimeError:
            return "runtime error"
        }
    }
}

extension TestSuiteOutcome {
    public static func from(testLog: String) -> TestSuiteOutcome {
        
        if logContainsRuntimeError(testLog) {
            return .runtimeError
        } else if logContainsBuildError(testLog) {
            return .buildError
        } else if logContainsTestFailure(testLog) {
            return .failed
        }

        return .passed
    }

    static private func logContainsTestFailure(_ testLog: String) -> Bool {
        let entireTestLog = NSRange(testLog.startIndex... , in: testLog)
        let numberOfFailureMessages = testFailureRegEx.numberOfMatches(in: testLog, options: [], range: entireTestLog)
        return numberOfFailureMessages > 0 || testLog.contains("** TEST FAILED **")
    }

    static private var testFailureRegEx: NSRegularExpression {
        return try! NSRegularExpression(pattern: "with ([1-9]{1}[0-9]{0,}) failure", options: [])
    }

    static private func logContainsRuntimeError(_ testLog: String) -> Bool {
        return testLog.contains("Fatal error")
    }

    static private func logContainsBuildError(_ testLog: String) -> Bool {
        return testLog.contains("xcodebuild: error:") ||
            testLog.contains("error: terminated") ||
            testLog.contains("failed with a nonzero exit code") ||
            testLog.contains("Testing cancelled because the build failed")
    }
}
