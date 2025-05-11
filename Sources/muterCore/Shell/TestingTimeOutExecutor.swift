import Foundation

protocol TestingTimeOutExecutor {
    func signal() -> Int
    func wait(timeout: DispatchTime) -> DispatchTimeoutResult
}

enum TestingExecutionResult {
    case success
    case timeOut
}

extension TestingTimeOutExecutor {
    func runTestProcess(
        _ process: Process,
        withTimeOut timeOut: TimeInterval
    ) throws -> TestingExecutionResult {
        process.terminationHandler = { _ in
            _ = signal()
        }

        try process.run()
        let result = wait(timeout: current.instant() + timeOut)

        if result == .success {
            return .success
        } else {
            process.terminate()
            return .timeOut
        }
    }
}

extension DispatchSemaphore: TestingTimeOutExecutor {}
