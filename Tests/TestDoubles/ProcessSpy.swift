import Foundation
@testable import muterCore

final class ProcessSpy: ProcessWrapper {
    private let queue = Queue<Data>()
    var stdoutToBeReturned = "" {
        didSet {
            stdoutToBeReturned
                .data(using: .utf8)
                .map(queue.enqueue)
        }
    }

    override var processData: Data? {
        queue.dequeue()
    }

    var runCalled = false
    override func run() throws {
        runCalled = true
    }

    var waitUntilExitCalled = false
    override func waitUntilExit() {
        waitUntilExitCalled = true
    }
}
