import Foundation

/// Turns Swift symbol references (USRs such as `s:Si1loiySbSi_SitFZ`) into signatures with types,
/// such as `static Swift.Int.< infix(Swift.Int, Swift.Int) -> Swift.Bool`. It runs the toolchain's
/// `swift-demangle` once for all the names.
struct SwiftDemangler {
    let executable: URL

    init(toolchain: SwiftToolchain) {
        executable = toolchain.tool("swift-demangle")
    }

    /// The signature of each Swift USR in `usrs`. Other USRs, such as Objective-C ones, and names
    /// that `swift-demangle` cannot read are left out.
    func demangle(_ usrs: [String]) -> [String: String] {
        let swiftUSRs = Array(Set(usrs.filter { $0.hasPrefix("s:") })).sorted()
        guard !swiftUSRs.isEmpty else {
            return [:]
        }

        let mangledNames = swiftUSRs.map { "$s" + $0.dropFirst(2) }
        guard let output = run(input: mangledNames.joined(separator: "\n") + "\n") else {
            return [:]
        }

        let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var signatures: [String: String] = [:]
        for (index, usr) in swiftUSRs.enumerated() where index < lines.count {
            // `swift-demangle` prints a name that it cannot read as it is.
            if lines[index] != mangledNames[index] {
                signatures[usr] = lines[index]
            }
        }
        return signatures
    }

    /// The input goes through a file: a pipe would block when the output fills its buffer before
    /// all the input is written.
    private func run(input: String) -> String? {
        let inputFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("muter-demangle-\(UUID().uuidString).txt")
        guard (try? input.write(to: inputFile, atomically: true, encoding: .utf8)) != nil,
              let inputHandle = try? FileHandle(forReadingFrom: inputFile)
        else {
            return nil
        }
        defer {
            try? inputHandle.close()
            try? FileManager.default.removeItem(at: inputFile)
        }

        let process = Foundation.Process()
        process.executableURL = executable
        process.standardInput = inputHandle
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else {
            return nil
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return process.terminationStatus == 0 ? String(data: data, encoding: .utf8) : nil
    }
}
