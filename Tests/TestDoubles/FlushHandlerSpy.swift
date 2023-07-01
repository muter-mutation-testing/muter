import Foundation

final class FlushHandlerSpy {
    private(set) var flushHandlerWasCalled = false

    func flush() {
        flushHandlerWasCalled = true
    }
}
