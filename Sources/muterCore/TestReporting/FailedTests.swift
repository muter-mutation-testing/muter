import Foundation

/// The number of tests that failed in a test run, read from its log.
enum FailedTests {
    /// The failed XCTest tests plus the failed Swift Testing tests, or `nil` when the log has
    /// neither framework's summary (for example, the build failed or the run was stopped).
    static func count(in testLog: String) -> Int? {
        let xcTest = xcTestFailures(in: testLog)
        let swiftTesting = swiftTestingFailures(in: testLog)

        guard xcTest != nil || swiftTesting != nil else {
            return nil
        }

        return (xcTest ?? 0) + (swiftTesting ?? 0)
    }

    /// XCTest prints `Executed 12 tests, with 2 failures (0 unexpected) …` for each suite and for the
    /// whole run. The whole run's line has the highest count, also when the runner restarted after
    /// a crash, because it then prints the totals of all launches.
    static func xcTestFailures(in testLog: String) -> Int? {
        let pattern = #"Executed \d+ tests?, with (\d+) failures?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(testLog.startIndex..., in: testLog)
        let counts = regex.matches(in: testLog, range: range).compactMap { match -> Int? in
            Range(match.range(at: 1), in: testLog).flatMap { Int(testLog[$0]) }
        }

        return counts.max()
    }

    /// Swift Testing prints `✘ Test name() failed after …` once for each failed test, and a
    /// `Test run with N tests …` summary at the end.
    static func swiftTestingFailures(in testLog: String) -> Int? {
        let lines = testLog.components(separatedBy: .newlines).map(\.trimmed)
        guard lines.contains(where: { $0.contains("Test run with") }) else {
            return nil
        }

        let failedTests = lines
            .filter { $0.hasPrefix("✘ Test ") && !$0.hasPrefix("✘ Test run") }
            .compactMap { line in line.range(of: " failed after ").map { String(line[..<$0.lowerBound]) } }

        return Set(failedTests).count
    }
}
