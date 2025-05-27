import Foundation
@testable import muterCore

final class TestingTimeOutExecutorSpy: TestingTimeoutExecution {

    private(set) var withTimeLimitCalled = false
    private(set) var timeLimitPassed: TimeInterval = 0

    var shouldSucceed = true
    func withTimeLimit(
        _ timeLimit: TimeInterval,
        _ body: @escaping @Sendable () async throws -> Void,
        timeoutHandler: @escaping @Sendable () async throws -> Void
    ) async throws {
        withTimeLimitCalled = true
        timeLimitPassed = timeLimit

        shouldSucceed
            ? try await body()
            : try await timeoutHandler()
    }
}
