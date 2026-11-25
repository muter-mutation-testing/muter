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

        XCTAssertFalse(rewritten.contains("ProcessInfo.processInfo.environment["), rewritten)
        XCTAssertTrue(rewritten.contains("__SwiftMutator.environment[\""), rewritten)
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

    private func rewrite(_ text: String) throws -> String {
        let source = SourceCodeInfo(path: "/path/to/Sample.swift", code: Parser.parse(source: text))
        let mapping = generateSchemataMappings(for: source).first ?? SchemataMutationMapping(filePath: source.path)
        return MuterRewriter(mapping).rewrite(source.code).description
    }
}
