import Foundation

let isMuterRunningKey = "IS_MUTER_RUNNING"
let isMuterRunningValue = "YES"

extension Process {
    struct Factory {
        static func makeProcess() -> Process {
            let process = Process()
            process.qualityOfService = .userInitiated

            var environment = ProcessInfo.processInfo.environment
            environment[isMuterRunningKey] = isMuterRunningValue
            process.environment = environment

            return process
        }
    }

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

extension ProcessWrapper {
    enum Factory {
        static func makeProcess() -> ProcessWrapper {
            let process = ProcessWrapper()
            process.qualityOfService = .userInitiated
            process.environment = ProcessInfo.processInfo.environment
            
            return process
        }
    }
}
