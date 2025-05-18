import Foundation

extension Foundation.Process: MuterProcess {}

extension Foundation.Process {
    #if os(macOS)
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
