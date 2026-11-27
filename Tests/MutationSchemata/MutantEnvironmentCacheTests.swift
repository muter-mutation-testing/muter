@testable import muterCore
import SwiftParser
import SwiftSyntax
import XCTest

/// Every mutated block asks "is my mutant active?" each time it runs. Asking with
/// `ProcessInfo.processInfo.environment[id]` rebuilds the whole environment dictionary on every
/// call, about 76 µs, and in hot code that slowed SwiftProjectLint's test run from ~9 s to ~93 s for
/// every mutant. The rewritten file now reads one lazily initialised copy, about 0.16 µs a call.
final class MutantEnvironmentCacheTests: MuterTestCase {

    func test_switchesReadTheFileCacheInsteadOfTheLiveEnvironment() throws {
        let rewritten = try rewrite("""
        func check(_ value: Int) -> Bool {
            return value > 1
        }
        """)

        // Only the cache at the end of the file reads the live environment.
        XCTAssertEqual(rewritten.components(separatedBy: "ProcessInfo.processInfo.environment[").count - 1, 1, rewritten)
        XCTAssertTrue(rewritten.contains("__SwiftMutator.activeMutant == 1 "), rewritten)
    }

    func test_theCacheIsDeclaredOnceAtTheEndOfAMutatedFile() throws {
        let rewritten = try rewrite("""
        func first(_ value: Int) -> Bool {
            return value > 1
        }

        func second(_ value: Int) -> Bool {
            return value < 9
        }
        """)

        let declarations = rewritten.components(separatedBy: "enum __SwiftMutator").count - 1
        XCTAssertEqual(declarations, 1, rewritten)
        let lastLine = rewritten.split(separator: "\n").last.map(String.init)
        XCTAssertEqual(lastLine?.trimmingCharacters(in: .whitespaces), "}")
        XCTAssertFalse(Parser.parse(source: rewritten).hasError, rewritten)
    }

    func test_aFileWithoutMutantsIsLeftUnchanged() throws {
        let text = "func constant() -> Int { 4 }\n"
        XCTAssertEqual(try rewrite(text), text)
    }

    // In a module isolated to the main actor by default, the cache was isolated to the main actor
    // too, and a switch in nonisolated code could not read it.
    func test_theRewrittenFileBuildsInAModuleIsolatedToTheMainActorByDefault() throws {
        let rewritten = try rewrite("""
        import Foundation

        nonisolated func check(_ value: Int) -> Bool {
            return value > 1
        }
        """)

        let errors = try typecheck(rewritten, arguments: ["-swift-version", "6", "-default-isolation", "MainActor"])
        try XCTSkipIf(
            errors.contains("unknown argument: '-default-isolation'"),
            "-default-isolation needs Swift 6.2 or later"
        )
        XCTAssertEqual(errors, "", rewritten)
    }

    /// Type-checks `source` with the active toolchain's compiler and returns what it printed.
    private func typecheck(_ source: String, arguments: [String]) throws -> String {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MutantEnvironmentCacheTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("Sample.swift")
        try source.write(to: file, atomically: true, encoding: .utf8)

        let process = Foundation.Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        #if os(macOS)
        process.arguments = ["xcrun", "swiftc"]
        #else
        process.arguments = ["swiftc"]
        #endif
        process.arguments! += ["-typecheck"] + arguments + [file.path]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return String(decoding: data, as: UTF8.self)
    }

    private func rewrite(_ text: String) throws -> String {
        let source = SourceCodeInfo(path: "/path/to/Sample.swift", code: Parser.parse(source: text))
        let mapping = generateSchemataMappings(for: source).first ?? SchemataMutationMapping(filePath: source.path)
        return MuterRewriter(mapping).rewrite(source.code).description
    }
}
