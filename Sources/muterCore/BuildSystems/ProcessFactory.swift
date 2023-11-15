import Foundation

let isMuterRunningKey = "IS_MUTER_RUNNING"
let isMuterRunningValue = "YES"

extension Process {
    enum Factory {
        static func makeProcess() -> Process {
            let process = Process()
            process.qualityOfService = .userInitiated

            process.environment = [
                isMuterRunningKey: isMuterRunningValue
            ]

            return process
        }
    }

    #if !os(Linux)
    @objc
    var processData: Data? {
        (standardOutput as? Pipe)?.readStringToEndOfFile()
    }
    #else
    var processData: Data? {
        (standardOutput as? Pipe)?.readStringToEndOfFile()
    }
    #endif

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
