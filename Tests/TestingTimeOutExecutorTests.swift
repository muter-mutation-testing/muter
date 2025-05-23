@testable import muterCore
import XCTest

final class TestingTimeOutExecutorTests: MuterTestCase {
    private let sut = TestingTimeOutExecutor()

    func test_timeOut() async throws {
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
