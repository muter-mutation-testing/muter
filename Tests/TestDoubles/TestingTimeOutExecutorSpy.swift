import Foundation
@testable import muterCore

final class TestingTimeOutExecutorSpy: TestingTimeoutExecution {

    private(set) var withTimeLimitCalled = false
    private(set) var timeLimitPassed: TimeInterval = 0

    var shouldSucceed = true
    func withTimeLimit<T>(
        _ timeLimit: TimeInterval,
        _ body: @escaping @Sendable () async throws -> T,
        timeoutHandler: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        withTimeLimitCalled = true
        timeLimitPassed = timeLimit

        return shouldSucceed
            ? try await body()
            : try await timeoutHandler()
    }
}
