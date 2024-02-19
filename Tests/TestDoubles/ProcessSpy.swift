import Foundation
@testable import muterCore

final class ProcessSpy: Process {
    override var standardOutput: Any? {
        get {
            queue.dequeue()
        } set { }
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

    private let queue = Queue<FakePipe>()
    var stdoutToBeReturned = "" {
        didSet {
            stdoutToBeReturned
                .data(using: .utf8)
                .map(FakePipe.init(data:))
                .map(queue.enqueue)
        }
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

private class FakePipe: Pipeable {
    private let fileHandle: FakeFileHandle

    init(data: Data) {
        fileHandle = FakeFileHandle(data: data)
    }

    var fileHandleForReading: FileHandle {
        fileHandle
    }
}

private class FakeFileHandle: FileHandle {
    private let data: Data

    #if os(Linux)
    init(data: Data) {
        self.data = data
        super.init(fileDescriptor: 0, closeOnDealloc: true)
    }
    #else
    init(data: Data) {
        self.data = data
        super.init()
    }
    #endif

    @available(*, unavailable) required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func readDataToEndOfFile() -> Data {
        data
    }
}
