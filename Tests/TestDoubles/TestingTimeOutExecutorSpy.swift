import Foundation
@testable import muterCore

final class TestingTimeOutExecutorSpy: TestingTimeOutExecutor {
    func signal() -> Int {
        0
    }

    private(set) var waitCalled = false
    private(set) var timeoutPassed: DispatchTime? = nil
    private(set) var timeoutResultToBeReturned: DispatchTimeoutResult = .success
    func wait(timeout: DispatchTime) -> DispatchTimeoutResult {
        waitCalled = true
        timeoutPassed = timeout

        return timeoutResultToBeReturned
    }
}
