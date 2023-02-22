import Foundation

@testable import muterCore

final class ProcessSpy: Process {
    private var _standardOutput: Any?
    override var standardOutput: Any? {
        get {
            return _standardOutput
        } set {
            _standardOutput = newValue
        }
    }
    
    private var _standardError: Any?
    override var standardError: Any? {
        get {
            return _standardError
        } set {
            _standardError = newValue
        }
    }
    
    private var _launchPath: String?
    override var launchPath: String? {
        get {
            return _launchPath
        }
        set {
            _launchPath = newValue
        }
    }
    
    private var _arguments: [String]?
    override var arguments: [String]? {
        get {
            return _arguments
        }
        set {
            _arguments = newValue
        }
    }
    
    private var _environment: [String: String]?
    override var environment: [String : String]? {
        get {
           return _environment
        }
        set {
            _environment = newValue
        }
    }
    
    private let queue = Queue<Data>()
    var stdoutToBeReturned = "" {
        didSet {
            stdoutToBeReturned
                .data(using: .utf8)
                .map(queue.enqueue)
        }
    }
    
    override var processData: Data? {
        return queue.dequeue()
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
