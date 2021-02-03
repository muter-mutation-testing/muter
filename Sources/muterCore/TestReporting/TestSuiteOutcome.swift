import Foundation

public enum TestSuiteOutcome: String, Codable, CaseIterable {
    case passed
    case failed
    case buildError
    case runtimeError

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
        }
    }
}

extension TestSuiteOutcome {
    public static func from(testLog: String, terminationStatus: Int32) -> TestSuiteOutcome {

        if !terminationStatusIsSuccess(terminationStatus) {
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
        return numberOfFailureMessages > 0 ||
            testLog.contains(testFailedMessage(from: .xcodebuild)) ||
            testLog.contains(testFailedMessage(from: .buck))
    }

    static private func testFailedMessage(from binaryType: BinaryType) -> String {
        switch binaryType {
        case .xcodebuild: return "** TEST FAILED **"
        case .buck: return "TESTS FAILED: "
        }
    }

    static private var testFailureRegEx: NSRegularExpression {
        return try! NSRegularExpression(pattern: "with ([1-9]{1}[0-9]{0,}) failure", options: [])
    }

    static private func terminationStatusIsSuccess(_ terminationStatus: Int32) -> Bool {
        return terminationStatus == 0
    }

    static private func logContainsBuildError(_ testLog: String) -> Bool {
        return testLog.contains("xcodebuild: error:") ||
            testLog.contains("error: terminated") ||
            testLog.contains("failed with a nonzero exit code") ||
            testLog.contains("Testing cancelled because the build failed") ||
            testLog.contains("Command failed with exit code 1.")
    }
}

private enum BinaryType {
    case xcodebuild
    case buck
}
