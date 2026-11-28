@testable import muterCore
import XCTest

/// Compiles Swift files with an index store, for the tests that read one.
enum IndexStoreFixture {
    /// Compiles each file on its own into `directory`, and writes the index to `indexStore`.
    static func compile(_ files: [URL], into directory: URL, indexStore: URL, toolchain: SwiftToolchain) throws {
        for file in files {
            let process = Foundation.Process()
            #if os(macOS)
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["swiftc"]
            #else
            process.executableURL = toolchain.tool("swiftc")
            process.arguments = []
            #endif
            process.arguments! += [
                "-parse-as-library", "-module-name", "Fixture",
                "-c", file.path, "-o", directory.appendingPathComponent(file.lastPathComponent + ".o").path,
                "-index-store-path", indexStore.path, "-index-ignore-system-modules",
            ]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try process.run()
            process.waitUntilExit()
            XCTAssertEqual(process.terminationStatus, 0, "swiftc could not compile \(file.lastPathComponent)")
        }
    }
}
