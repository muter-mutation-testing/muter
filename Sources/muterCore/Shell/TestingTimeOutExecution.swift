import Foundation

protocol TestingTimeoutExecution {
    func withTimeLimit(
        _ timeLimit: TimeInterval,
        _ body: @escaping @Sendable () async throws -> Void,
        timeoutHandler: @escaping @Sendable () async throws -> Void
    ) async throws
}

enum TestingExecutionResult {
    case success
    case timeout
}

struct TestingTimeoutExecutor: TestingTimeoutExecution {
    func withTimeLimit(
        _ timeLimit: TimeInterval,
        _ body: @escaping @Sendable () async throws -> Void,
        timeoutHandler: @escaping @Sendable () async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            defer {
                print("defer", group.isCancelled)
                group.cancelAll()
            }

            group.addTask {
                // If sleep() returns instead of throwing a CancellationError, that means
                // the timeout was reached before this task could be cancelled, so call
                // the timeout handler.
                try await Task.sleep(seconds: timeLimit)
                print("try await Task.sleep(seconds: timeLimit)", Task.isCancelled)
                try await timeoutHandler()
            }

            group.addTask(operation: body)


            print("before next", group.isCancelled)
            try await group.next()
            print("after next", group.isCancelled)
        }
    }
}
