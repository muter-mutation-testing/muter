import Foundation

let isMuterRunningKey = "IS_MUTER_RUNNING"
let isMuterRunningValue = "YES"

typealias Process = MuterProcess

protocol MuterProcess: AnyObject {
    var terminationStatus: Int32 { get }
    var environment: [String: String]? { get set }
    var arguments: [String]? { get set }
    var executableURL: URL? { get set }
    var standardOutput: Any? { get set }
    var standardError: Any? { get set }

    func runProcess(
        url: String,
        arguments args: [String]
    ) -> Data?

    func run() throws

    func waitUntilExit()
}

extension MuterProcess {
    func runProcess(
        url: String,
        arguments: [String]
    ) -> String? {
        guard let output: Data = runProcess(url: url, arguments: arguments) else {
            return nil
        }

        return String(data: output, encoding: .utf8)
    }
}

extension Foundation.Process: MuterProcess {}

enum MuterProcessFactory {
    static func makeProcess() -> MuterProcess {
        let process = Foundation.Process()
        process.qualityOfService = .userInitiated

        var environment = ProcessInfo.processInfo.environment
        environment[isMuterRunningKey] = isMuterRunningValue
        process.environment = environment

        return process
    }
}

extension Foundation.Process {
    #if !os(Linux)
    @objc
    #endif
    var processData: Data? {
        (standardOutput as? Pipe)?.readStringToEndOfFile()
    }

    func runProcess(
        url: String,
        arguments args: [String]
    ) -> Data? {
        let pipe = Pipe()
        standardOutput = pipe
        standardError = FileHandle.nullDevice
        executableURL = URL(fileURLWithPath: url)
        arguments = args

        try? run()

        let output = processData

        waitUntilExit()

        return output
    }
}

extension Pipe {
    func readStringToEndOfFile() -> Data? {
        let data: Data
        if #available(OSX 10.15.4, *) {
            data = (try? fileHandleForReading.readToEnd()) ?? Data()
        } else {
            data = fileHandleForReading.readDataToEndOfFile()
        }

        return data
    }
}
