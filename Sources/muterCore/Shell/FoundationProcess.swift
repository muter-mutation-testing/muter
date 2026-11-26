import Foundation

extension Foundation.Process: MuterProcess {}

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
        runProcess(url: url, arguments: args, includingStandardError: false)
    }

    func runProcessIncludingStandardError(
        url: String,
        arguments args: [String]
    ) -> Data? {
        runProcess(url: url, arguments: args, includingStandardError: true)
    }

    private func runProcess(
        url: String,
        arguments args: [String],
        includingStandardError: Bool
    ) -> Data? {
        let pipe = Pipe()
        standardOutput = pipe
        standardError = includingStandardError ? pipe : FileHandle.nullDevice
        executableURL = URL(fileURLWithPath: url)
        arguments = args

        try? run()

        let output = processData

        pipe.fileHandleForReading.closeFile()

        waitUntilExit()

        return output
    }
}

private extension Pipe {
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
