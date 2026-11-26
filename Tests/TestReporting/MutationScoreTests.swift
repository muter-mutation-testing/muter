@testable import muterCore
import XCTest

final class MutationScoreTests: XCTestCase {
    func test_aTimeoutKillsTheMutant() {
        XCTAssertEqual(mutationScore(from: [.timeout, .passed]), 50)
        XCTAssertTrue(TestSuiteOutcome.timeout.isKilled)
    }

    func test_killedOutcomes() {
        XCTAssertEqual(TestSuiteOutcome.allCases.filter(\.isKilled), [.failed, .runtimeError, .timeout])
    }

    func test_theScoreIsRounded() {
        // 2 of 3 is 66.7%.
        XCTAssertEqual(mutationScore(from: [.failed, .failed, .passed]), 67)
        // 1 of 3 is 33.3%.
        XCTAssertEqual(mutationScore(from: [.failed, .passed, .passed]), 33)
    }

    func test_buildErrorsDoNotCount() {
        XCTAssertEqual(mutationScore(from: [.failed, .buildError]), 100)
    }
}
