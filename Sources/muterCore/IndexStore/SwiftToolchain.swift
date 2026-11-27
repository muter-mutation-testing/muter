import Foundation

/// The Swift toolchain that builds the project. Its `usr` folder has the index store library and
/// the `swift-demangle` tool that match the compiler, so they can read what the compiler wrote.
struct SwiftToolchain: Equatable {
    /// The toolchain's `usr` folder.
    let usrDirectory: URL

    var libraryDirectory: URL { usrDirectory.appendingPathComponent("lib") }

    func tool(_ name: String) -> URL {
        usrDirectory.appendingPathComponent("bin").appendingPathComponent(name)
    }

    /// The toolchain of the `swift` that `xcrun` selects on macOS, or the first `swift` on `PATH`
    /// on other systems. `nil` when there is none.
    static func current(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> SwiftToolchain? {
        #if os(macOS)
        guard let swift = run("/usr/bin/xcrun", ["--find", "swift"]) else {
            return nil
        }
        return SwiftToolchain(swiftExecutable: URL(fileURLWithPath: swift))
        #else
        let directories = (environment["PATH"] ?? "").split(separator: ":").map(String.init)
        for directory in directories {
            let swift = URL(fileURLWithPath: directory).appendingPathComponent("swift")
            if FileManager.default.isExecutableFile(atPath: swift.path) {
                return SwiftToolchain(swiftExecutable: swift.resolvingSymlinksInPath())
            }
        }
        return nil
        #endif
    }

    /// `<toolchain>/usr/bin/swift` gives `<toolchain>/usr`.
    init(swiftExecutable: URL) {
        usrDirectory = swiftExecutable.deletingLastPathComponent().deletingLastPathComponent()
    }

    init(usrDirectory: URL) {
        self.usrDirectory = usrDirectory
    }

    private static func run(_ executable: String, _ arguments: [String]) -> String? {
        let process = Foundation.Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else {
            return nil
        }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            return nil
        }
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
    }
}
