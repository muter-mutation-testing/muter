import Foundation
@testable import muterCore

final class ProcessSpy: MuterProcess {
    var terminationStatus: Int32 { 0 }
    var environment: [String: String]?
    var arguments: [String]?
    var executableURL: URL?
    var standardOutput: Any?
    var standardError: Any?

    private let queue = Queue<String>()
    var stdoutToBeReturned = "" {
        didSet {
            queue.enqueue(stdoutToBeReturned)
        }
    }

    var runCalled = false
    func run() throws {
        runCalled = true
    }

    var waitUntilExitCalled = false
    func waitUntilExit() {
        waitUntilExitCalled = true
    }

    func runProcess(url: String, arguments args: [String]) -> Data? {
        executableURL = URL(string: url)
        arguments = args

        return queue.dequeue()?.data(using: .utf8)
    }
}
