import Foundation

let isMuterRunningKey = "IS_MUTER_RUNNING"
let isMuterRunningValue = "YES"

extension ProcessWrapper {
    enum Factory {
        static func makeProcess() -> ProcessWrapper {
            let process = ProcessWrapper()
            process.qualityOfService = .userInitiated

            process.environment = [
                isMuterRunningKey: isMuterRunningValue
            ]

            return process
        }
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
