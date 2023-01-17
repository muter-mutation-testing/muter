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
    
    private let queue = Queue<Data>()
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
