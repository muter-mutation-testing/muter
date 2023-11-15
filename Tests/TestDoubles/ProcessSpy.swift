import Foundation
@testable import muterCore

final class ProcessSpy: Process {
    let queue = Queue<Data>()
    var stdoutToBeReturned = "" {
        didSet {
            stdoutToBeReturned
                .data(using: .utf8)
                .map(queue.enqueue)
        }
    }
    
    private var _standardOutput: Any?
    override var standardOutput: Any? {
        get {
            _standardOutput
        } set {
            _standardOutput = FakePipe(data: queue.dequeue() ?? .init())
        }
    }
    
    private var _standardError: Any?
    override var standardError: Any? {
        get {
            _standardError
        } set {
            _standardError = newValue
        }
    }
    
    private var _launchPath: String?
    override var launchPath: String? {
        get {
            _launchPath
        }
        set {
            _launchPath = newValue
        }
    }
    
    private var _arguments: [String]?
    override var arguments: [String]? {
        get {
            _arguments
        }
        set {
            _arguments = newValue
        }
    }
    
    private var _environment: [String: String]?
    override var environment: [String: String]? {
        get {
            _environment
        }
        set {
            _environment = newValue
        }
    }
    
    private(set) var runCalled: Bool = false
    override func run() throws {
        runCalled = true
    }
    
    private(set) var waitUntilExitCalled = false
    override func waitUntilExit() {
        waitUntilExitCalled = true
    }
}

private class FakePipe: Pipe {
    private let data: Data
    init(data: Data) {
        self.data = data
    }

    override var fileHandleForReading: FileHandle {
        FakeFileHandle(data: data)
    }
    
    override var fileHandleForWriting: FileHandle {
        FakeFileHandle(data: data)
    }
}

private class FakeFileHandle: FileHandle {
    private let data: Data
    
    init(data: Data) {
        self.data = data
        super.init()
    }
    
    #if !os(Linux)
    required init?(coder: NSCoder) {
        self.data = .init()
        super.init(coder: coder)
    }
    #endif
    
    override func readDataToEndOfFile() -> Data {
        data
    }
}
