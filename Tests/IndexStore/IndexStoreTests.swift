@testable import muterCore
import SwiftParser
import SwiftSyntax
import XCTest

/// These tests compile a small Swift file with an index store, then read the store with the
/// toolchain's `libIndexStore`. They skip when the toolchain has no such library.
final class IndexStoreTests: XCTestCase {
    private static let fixture = """
    struct Point: Comparable {
        let x: Int

        static func < (lhs: Point, rhs: Point) -> Bool {
            lhs.x < rhs.x // int-compare-in-point
        }
    }

    struct Box {}

    extension Box: Equatable {}

    func larger(_ a: Int, _ b: Int) -> Int {
        return a > b ? a : b // larger-compare
    }

    func greeting(_ name: String) -> String {
        return "Hi " + name // greeting-plus
    }

    func samePoint(_ p: Point, _ q: Point) -> Bool {
        return p < q // point-compare
    }
    """

    private var directory: URL!
    private var sourceFile: URL!
    private var toolchain: SwiftToolchain!
    private var library: IndexStoreLibrary!
    private var index: SymbolIndex!
    private var demangler: SwiftDemangler!

    override func setUpWithError() throws {
        try super.setUpWithError()

        toolchain = try XCTUnwrap(SwiftToolchain.current(), "No Swift toolchain")
        guard let library = IndexStoreLibrary(toolchain: toolchain) else {
            throw XCTSkip("The toolchain at \(toolchain.usrDirectory.path) has no libIndexStore.")
        }
        self.library = library
        demangler = SwiftDemangler(toolchain: toolchain)

        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("muter-index-\(UUID().uuidString)")
            .resolvingSymlinksInPath()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        sourceFile = directory.appendingPathComponent("Fixture.swift")
        try Self.fixture.write(to: sourceFile, atomically: true, encoding: .utf8)

        let store = directory.appendingPathComponent("Store")
        try IndexStoreFixture.compile([sourceFile], into: directory, indexStore: store, toolchain: toolchain)
        index = try SymbolIndex(
            occurrences: IndexStore(path: store.path, library: library).occurrences(inFilesUnder: directory.path)
        )
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        try super.tearDownWithError()
    }

    // MARK: - Discovery

    /// A visitor walks the prepared code, which has extra lines at the top. It looks up a token at
    /// its position in the file on disk, which is where the compiler recorded it.
    func test_visitorFindsTheSymbolOfAnOperatorInPreparedCode() throws {
        let prepared = Parser.parse(source: "import Foundation\n" + Self.fixture)
        let visitor = ROROperator.Visitor(
            sourceCodeInfo: SourceCodeInfo(path: sourceFile.path, code: prepared),
            regionsWithoutCoverage: []
        )
        visitor.sourceCodePreparationChange = MutationSourceCodePreparationChange(newLines: 1)
        let greaterThan = try XCTUnwrap(prepared.tokens(viewMode: .sourceAccurate).first { $0.text == ">" })

        XCTAssertNil(visitor.referencedSymbol(at: greaterThan), "No index, no symbol")

        visitor.symbolIndex = index
        let symbol = try XCTUnwrap(visitor.referencedSymbol(at: greaterThan))
        XCTAssertEqual(demangled(symbol), "static Swift.Int.> infix(Swift.Int, Swift.Int) -> Swift.Bool")
    }

    // MARK: - Lookups

    func test_operatorResolvesToTheFunctionOfItsType() throws {
        let symbol = try XCTUnwrap(referencedSymbol(">", onLineWith: "larger-compare"))

        XCTAssertEqual(symbol.name, ">(_:_:)")
        XCTAssertEqual(demangled(symbol), "static Swift.Int.> infix(Swift.Int, Swift.Int) -> Swift.Bool")
    }

    func test_stringConcatenationResolvesToString() throws {
        let symbol = try XCTUnwrap(referencedSymbol("+", onLineWith: "greeting-plus"))

        XCTAssertEqual(demangled(symbol), "static Swift.String.+ infix(Swift.String, Swift.String) -> Swift.String")
    }

    func test_customOperatorResolvesToTheProjectType() throws {
        let symbol = try XCTUnwrap(referencedSymbol("<", onLineWith: "point-compare"))

        XCTAssertTrue(try XCTUnwrap(demangled(symbol)).hasPrefix("static Fixture.Point.< infix"), "\(demangled(symbol) ?? "")")
    }

    func test_functionDefinitionHasItsReturnType() throws {
        let position = try position(of: "larger", onLineWith: "func larger")
        let symbol = try XCTUnwrap(index.definedSymbol(inFile: sourceFile.path, line: position.line, column: position.column))

        XCTAssertTrue(symbol.kind.isFunction)
        XCTAssertEqual(demangled(symbol), "Fixture.larger(Swift.Int, Swift.Int) -> Swift.Int")
    }

    func test_conformancesInTheTypeAndInAnExtension() throws {
        let point = try definedType("Point", onLineWith: "struct Point")
        let box = try definedType("Box", onLineWith: "struct Box")
        let comparable = "s:SL"
        let equatable = "s:SQ"

        XCTAssertTrue(index.conforms(typeUSR: point.usr, toProtocolUSR: comparable))
        XCTAssertTrue(index.conforms(typeUSR: box.usr, toProtocolUSR: equatable))
        XCTAssertFalse(index.conforms(typeUSR: box.usr, toProtocolUSR: comparable))
    }

    func test_positionWithoutASymbol() {
        XCTAssertNil(index.referencedSymbol(inFile: sourceFile.path, line: 1, column: 1))
        XCTAssertNil(index.referencedSymbol(inFile: "/no/such/file.swift", line: 14, column: 14))
    }

    // MARK: - Store and library

    func test_onlyTheFilesUnderTheDirectory() throws {
        let store = try IndexStore(path: directory.appendingPathComponent("Store").path, library: library)

        XCTAssertFalse(store.occurrences(inFilesUnder: directory.path).isEmpty)
        XCTAssertTrue(store.occurrences(inFilesUnder: "/no/such/directory").isEmpty)
    }

    func test_missingLibrary() {
        XCTAssertNil(IndexStoreLibrary(path: "/no/such/libIndexStore.dylib"))
        XCTAssertNil(IndexStoreLibrary(toolchain: SwiftToolchain(usrDirectory: URL(fileURLWithPath: "/no/such/usr"))))
    }

    func test_demanglerLeavesOutWhatItCannotRead() {
        let signatures = demangler.demangle(["s:Si1loiySbSi_SitFZ", "c:objc(cs)NSObject", "s:notAMangledName"])

        XCTAssertEqual(signatures, ["s:Si1loiySbSi_SitFZ": "static Swift.Int.< infix(Swift.Int, Swift.Int) -> Swift.Bool"])
    }

    // MARK: - Helpers

    /// The line and UTF-8 column, from 1, of `token` on the fixture line that contains `marker`.
    private func position(of token: String, onLineWith marker: String) throws -> (line: Int, column: Int) {
        let lines = Self.fixture.components(separatedBy: "\n")
        let index = try XCTUnwrap(lines.firstIndex { $0.contains(marker) }, "No line with \(marker)")
        let range = try XCTUnwrap(lines[index].range(of: " \(token) ") ?? lines[index].range(of: token))
        let start = lines[index][range].hasPrefix(" ") ? lines[index].index(after: range.lowerBound) : range.lowerBound
        return (index + 1, lines[index].utf8.distance(from: lines[index].startIndex, to: start) + 1)
    }

    private func referencedSymbol(_ token: String, onLineWith marker: String) throws -> IndexSymbol? {
        let position = try position(of: token, onLineWith: marker)
        return index.referencedSymbol(inFile: sourceFile.path, line: position.line, column: position.column)
    }

    private func definedType(_ name: String, onLineWith marker: String) throws -> IndexSymbol {
        let position = try position(of: name, onLineWith: marker)
        return try XCTUnwrap(index.definedSymbol(inFile: sourceFile.path, line: position.line, column: position.column))
    }

    private func demangled(_ symbol: IndexSymbol) -> String? {
        demangler.demangle([symbol.usr])[symbol.usr]
    }
}
