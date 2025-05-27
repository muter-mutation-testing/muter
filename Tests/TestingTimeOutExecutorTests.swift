@testable import muterCore
import XCTest

final class TestingTimeoutExecutorTests: MuterTestCase {
    private let sut = TestingTimeoutExecutor()

    func test_timeout() async throws {
        let expect = expectation(description: #function)

        try await sut.withTimeLimit(1) {
            try await Task.sleep(seconds: 2)
        } timeoutHandler: {
            expect.fulfill()
        }

        await fulfillment(of: [expect], timeout: 5)
    }

    func test_success() async throws {
        let expect = expectation(description: #function)

        try await sut.withTimeLimit(2) {
            try await Task.sleep(seconds: 1)
            expect.fulfill()
        } timeoutHandler: {}

        await fulfillment(of: [expect], timeout: 5)
    }
}
