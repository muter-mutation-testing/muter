@testable import muterCore
import XCTest

final class LoadSymbolIndexTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("muter-load-index-\(UUID().uuidString)")
            .resolvingSymlinksInPath()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        try super.tearDownWithError()
    }

    private func state(indexStorePath: String?, sourceFiles: [String] = []) -> MutationTestState {
        let state = MutationTestState()
        state.apply([
            .projectCoverage(Coverage(percent: 100, indexStorePath: indexStorePath)),
            .sourceFileCandidatesDiscovered(sourceFiles),
        ])
        return state
    }

    func test_withoutAnIndexStore_nothingChanges() async throws {
        let changes = try await LoadSymbolIndex().run(with: state(indexStorePath: nil))

        XCTAssertEqual(changes, [])
    }

    func test_whenTheIndexStoreIsMissing_nothingChanges() async throws {
        let missing = directory.appendingPathComponent("NoStore").path

        let changes = try await LoadSymbolIndex().run(with: state(indexStorePath: missing))

        XCTAssertEqual(changes, [])
    }

    func test_withoutLibIndexStore_nothingChanges() async throws {
        let changes = try await LoadSymbolIndex(loadLibrary: { nil })
            .run(with: state(indexStorePath: directory.path))

        XCTAssertEqual(changes, [])
    }

    /// Only the files that Muter can mutate are read, and a path through a symbolic link matches
    /// the path that the compiler recorded.
    func test_readsTheIndexOfTheSourceFileCandidates() async throws {
        let toolchain = try XCTUnwrap(SwiftToolchain.current(), "No Swift toolchain")
        guard IndexStoreLibrary(toolchain: toolchain) != nil else {
            throw XCTSkip("The toolchain at \(toolchain.usrDirectory.path) has no libIndexStore.")
        }

        let sources = directory.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        let mutated = sources.appendingPathComponent("Mutated.swift")
        let other = sources.appendingPathComponent("Other.swift")
        try "func alpha() -> Int { 1 + 2 }\n".write(to: mutated, atomically: true, encoding: .utf8)
        try "func omega() -> Int { 3 + 4 }\n".write(to: other, atomically: true, encoding: .utf8)
        let store = directory.appendingPathComponent("Store")
        try IndexStoreFixture.compile([mutated, other], into: directory, indexStore: store, toolchain: toolchain)

        let link = directory.appendingPathComponent("Link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: sources)
        let candidate = link.appendingPathComponent("Mutated.swift").path

        let changes = try await LoadSymbolIndex()
            .run(with: state(indexStorePath: store.path, sourceFiles: [candidate]))

        guard case let .symbolIndexLoaded(index) = try XCTUnwrap(changes.first) else {
            return XCTFail("Expected a symbol index, got \(changes)")
        }
        XCTAssertEqual(index.definedSymbol(inFile: candidate, line: 1, column: 6)?.name, "alpha()")
        XCTAssertEqual(index.referencedSymbol(inFile: candidate, line: 1, column: 25)?.name, "+(_:_:)")
        XCTAssertNil(index.definedSymbol(inFile: other.path, line: 1, column: 6))
    }
}
