import Foundation

extension ProcessWrapper {
    enum Factory {
        static func makeProcess() -> ProcessWrapper {
            let process = ProcessWrapper()
            process.qualityOfService = .userInitiated
            process.environment = ProcessInfo.processInfo.environment

            return process
        }
    }

    func runProcess(
        url: String,
        arguments args: [String]
    ) -> Data? {
        let pipe = Pipe()
        standardError = pipe
        standardOutput = pipe
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
