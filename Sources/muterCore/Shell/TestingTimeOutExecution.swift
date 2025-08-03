import Foundation

protocol TestingTimeoutExecution {
    func withTimeLimit<T>(
        _ timeLimit: TimeInterval,
        _ body: @escaping @Sendable () async throws -> T,
        timeoutHandler: @escaping @Sendable () async throws -> T
    ) async throws -> T
}

enum TestingExecutionResult {
    case success
    case timeout
}

struct TestingTimeoutExecutor: TestingTimeoutExecution {
    func withTimeLimit<T>(
        _ timeLimit: TimeInterval,
        _ body: @escaping @Sendable () async throws -> T,
        timeoutHandler: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            defer {
                group.cancelAll()
            }

            group.addTask {
                // If sleep() returns instead of throwing a CancellationError, that means
                // the timeout was reached before this task could be cancelled, so call
                // the timeout handler.
                try await Task.sleep(nanoseconds: UInt64(timeLimit) * 1_000_000_000)
                return try await timeoutHandler()
            }

            group.addTask(operation: body)

            guard let result = try await group.next() else {
                throw CancellationError()
            }

            return result
        }
    }
}
