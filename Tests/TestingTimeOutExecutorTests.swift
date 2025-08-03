@testable import muterCore
import XCTest

final class TestingTimeoutExecutorTests: MuterTestCase {
    private let sut = TestingTimeoutExecutor()

    func test_timeout() async throws {
        let expect = expectation(description: #function)

        try await sut.withTimeLimit(1) {
            try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        } timeoutHandler: {
            expect.fulfill()
        }

        await fulfillment(of: [expect], timeout: 5)
    }

    func test_success() async throws {
        let expect = expectation(description: #function)

        try await sut.withTimeLimit(2) {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            expect.fulfill()
        } timeoutHandler: {}

        await fulfillment(of: [expect], timeout: 5)
    }
}
