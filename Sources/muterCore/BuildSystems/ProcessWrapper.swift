import Foundation

class ProcessWrapper {
    private(set) var process = Process()

    var launchPath: String {
        get { process.launchPath ?? "" }
        set { process.launchPath = newValue }
    }

    var executableURL: URL? {
        get { process.executableURL }
        set { process.executableURL = newValue }
    }

    var arguments: [String]? {
        get { process.arguments }
        set { process.arguments = newValue }
    }

    var environment: [String: String]? {
        get { process.environment }
        set { process.environment = newValue }
    }

    var currentDirectoryPath: String {
        get { process.currentDirectoryPath }
        set { process.currentDirectoryPath = newValue }
    }

    var standardInput: Any? {
        get { process.standardInput }
        set { process.standardInput = newValue }
    }

    var standardOutput: Any? {
        get { process.standardOutput }
        set { process.standardOutput = newValue }
    }

    var standardError: Any? {
        get { process.standardOutput }
        set { process.standardOutput = newValue }
    }

    var qualityOfService: QualityOfService {
        get { process.qualityOfService }
        set { process.qualityOfService = newValue }
    }

    var processData: Data? {
        (standardOutput as? Pipe)?.readStringToEndOfFile()
    }

    var terminationStatus: Int32 {
        process.terminationStatus
    }

    func run() throws {
        try process.run()
    }

    func waitUntilExit() {
        process.waitUntilExit()
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
