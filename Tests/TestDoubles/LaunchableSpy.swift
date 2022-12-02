import Foundation

@testable import muterCore

final class LaunchableSpy: Launchable {
    var executableURL: URL?
    var arguments: [String]?
    var standardOutput: Any?
    
    var stdoutToBeReturned = "" {
        didSet {
            stdoutToBeReturned
                .data(using: .utf8)
                .map(queue.enqueue)
        }
    }
    
    private let queue = Queue()
    var availableData: Data? {
        queue.dequeue()
    }
    
    var runCalled = false
    func run() throws {
        runCalled = true
    }
    
    var waitUntilExitCalled = false
    func waitUntilExit() {
        waitUntilExitCalled = true
    }
}

private class Queue {
    private var contents = [Data]()
    
    func dequeue() -> Data? {
        contents.isEmpty ? nil : contents.removeFirst()
    }
    
    func enqueue(_ data: Data) {
        contents.append(data)
    }
}
