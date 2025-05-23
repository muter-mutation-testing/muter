import Foundation

protocol TestingTimeOutExecution {
    func withTimeLimit(
        _ timeLimit: TimeInterval,
        _ body: @escaping @Sendable () async throws -> Void,
        timeoutHandler: @escaping @Sendable () -> Void
    ) async throws
}

enum TestingExecutionResult {
    case success
    case timeOut
}

struct TestingTimeOutExecutor: TestingTimeOutExecution {
    func withTimeLimit(
        _ timeLimit: TimeInterval,
        _ body: @escaping @Sendable () async throws -> Void,
        timeoutHandler: @escaping @Sendable () -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                // If sleep() returns instead of throwing a CancellationError, that means
                // the timeout was reached before this task could be cancelled, so call
                // the timeout handler.
                try await Task.sleep(seconds: timeLimit)
                timeoutHandler()
            }
            group.addTask(operation: body)

            defer {
                group.cancelAll()
            }
            try await group.next()!
        }
    }
}
