@testable import muterCore
import SwiftParser
import SwiftSyntax
import XCTest

/// These tests compile a fixture with an index store, because the operator mutates only what the
/// index shows to be arithmetic on numbers. They skip when the toolchain has no `libIndexStore`.
final class ArithmeticOperatorReplacementTests: XCTestCase {
    /// Each line with an operator ends with a marker: `mutate` when the operator should change,
    /// `keep` when it should not.
    private static let fixture = """
    import Foundation

    struct Money {
        var cents: Int

        static func + (lhs: Money, rhs: Money) -> Money {
            Money(cents: lhs.cents + rhs.cents) // mutate: parameters
        }
    }

    struct Cart {
        var discount = 0
        static let fee: UInt8 = 2

        func total(_ price: Int, _ shipping: Int) -> Int {
            price + shipping // mutate: parameters
        }

        func scaled(_ value: Double) -> Double {
            value * 2 // mutate: Double
        }

        func half(_ value: Double) -> Double {
            1.0 / 0.5 // mutate: Double, no build-time errors
        }

        func greeting(_ name: String) -> String {
            "Hi " + name // keep: String
        }

        func later(_ date: Date) -> Date {
            date + 60 // keep: Date
        }

        func sum(_ a: Money, _ b: Money) -> Money {
            a + b // keep: a project operator
        }

        func localConstant() -> UInt8 {
            let base: UInt8 = 10
            return base + 20 // keep: the compiler computes 10 - 20 and rejects it
        }

        func literals() -> Int {
            10 - 20 // keep: literals
        }

        func largest() -> Int {
            Int.max - 1 // keep: Int.max + 1 overflows at build time
        }

        func withDiscount(_ price: Int) -> Int {
            discount - 1 // mutate: a property
        }

        func withFee() -> UInt8 {
            Cart.fee + 1 // mutate: a static property of the project
        }

        func timesZero(_ value: Int) -> Int {
            value * 0 // keep: value / 0 does not build
        }

        func timesTwo(_ value: Int) -> Int {
            value * 2 // mutate: the new divisor is not zero
        }

        func divided(_ value: Int, by divisor: Int) -> Int {
            value / divisor // mutate: parameters
        }

        mutating func add(_ value: Int) {
            discount += value // mutate: a property and a parameter
        }

        func counter() -> UInt8 {
            var count: UInt8 = 0
            count += 1 // keep: a local variable and a literal
            return count
        }

        func shadowed(_ value: Int) -> UInt8 {
            if value > 0 {
                let value: UInt8 = 10
                return value + 20 // keep: a local constant hides the parameter
            }
            return 0
        }

        func doubled(_ values: [Int]) -> [Int] {
            values.map { $0 * 2 } // mutate: a closure parameter
        }

        func precedence(_ value: Int) -> Int {
            2 * 3 + value // mutate: only +, because * has only literals
        }

        func remainder(_ value: Int) -> Int {
            value % 3 // keep: no replacement for %
        }
    }

    func additive<T: AdditiveArithmetic>(_ a: T, _ b: T) -> T {
        a + b // mutate: AdditiveArithmetic has -
    }

    func product<T: Numeric>(_ a: T, _ b: T) -> T {
        a * b // keep: Numeric has no /
    }

    func ratio<T: BinaryInteger>(_ a: T, _ b: T) -> T {
        a / b // mutate: BinaryInteger has *
    }
    """

    private var directory: URL!
    private var sourceFile: URL!
    private var toolchain: SwiftToolchain!
    private var index: SymbolIndex!

    override func setUpWithError() throws {
        try super.setUpWithError()

        toolchain = try XCTUnwrap(SwiftToolchain.current(), "No Swift toolchain")
        guard let library = IndexStoreLibrary(toolchain: toolchain) else {
            throw XCTSkip("The toolchain at \(toolchain.usrDirectory.path) has no libIndexStore.")
        }

        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("muter-aor-\(UUID().uuidString)")
            .resolvingSymlinksInPath()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        sourceFile = directory.appendingPathComponent("Fixture.swift")
        try Self.fixture.write(to: sourceFile, atomically: true, encoding: .utf8)

        let store = directory.appendingPathComponent("Store")
        try IndexStoreFixture.compile([sourceFile], into: directory, indexStore: store, toolchain: toolchain)
        let occurrences = try IndexStore(path: store.path, library: library).occurrences(inFilesUnder: directory.path)
        let usrs = SymbolIndex.referencedUSRs(in: occurrences, named: ArithmeticOperatorReplacement.symbolNames)
        index = SymbolIndex(occurrences: occurrences, signatures: SwiftDemangler(toolchain: toolchain).demangle(usrs))
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        try super.tearDownWithError()
    }

    func test_mutatesOnlyTheArithmeticOfNumbers() throws {
        let mutants = mutants(with: index)

        let lines = Self.fixture.components(separatedBy: "\n")
        let mutated = Set(mutants.map { lines[$0.position.line - 1].trimmingCharacters(in: .whitespaces) })
        let expected = Set(lines.filter { $0.contains("// mutate") }.map { $0.trimmingCharacters(in: .whitespaces) })
        XCTAssertEqual(mutated.sorted(), expected.sorted())

        let precedence = mutants.filter { lines[$0.position.line - 1].contains("2 * 3 + value") }
        XCTAssertEqual(precedence.map(\.snapshot.before), ["+"], "Only + has an operand known at run time")
    }

    func test_swapsEachOperatorForItsCounterpart() throws {
        let changes = Set(mutants(with: index).map { "\($0.snapshot.before) \($0.snapshot.after)" })

        XCTAssertEqual(changes, ["+ -", "- +", "* /", "/ *", "+= -="])
    }

    func test_withoutAnIndex_mutatesNothing() throws {
        XCTAssertEqual(mutants(with: nil), [])
    }

    /// All mutants build together, so the mutated file must build with all of them.
    func test_theFileWithAllMutantsBuilds() throws {
        let code = Parser.parse(source: Self.fixture)
        let visitor = visitor(for: code, index: index)
        visitor.walk(code)
        let mapping = [visitor.schemataMappings].mergeByFilePath().numberedMutants().first
        let rewritten = MuterRewriter(try XCTUnwrap(mapping)).rewrite(code).description
        let mutatedFile = directory.appendingPathComponent("Mutated.swift")
        try rewritten.write(to: mutatedFile, atomically: true, encoding: .utf8)

        // The overflow and division-by-zero errors come from a pass after type checking.
        XCTAssertEqual(try compilerErrors(mutatedFile, arguments: ["-emit-sil", "-o", "/dev/null"]), "", rewritten)
    }

    // MARK: - Signatures

    func test_signatureOfAConcreteType() throws {
        let operation = try XCTUnwrap(ArithmeticOperation(
            signature: "static Swift.UInt8.+ infix(Swift.UInt8, Swift.UInt8) -> Swift.UInt8",
            operator: "+"
        ))

        XCTAssertTrue(operation.isConcreteInteger)
        XCTAssertTrue(operation.typeHas("-"))
    }

    func test_signatureOfACompoundAssignment() throws {
        let operation = try XCTUnwrap(ArithmeticOperation(
            signature: "static Swift.Double.*= infix(inout Swift.Double, Swift.Double) -> ()",
            operator: "*="
        ))

        XCTAssertFalse(operation.isConcreteInteger)
    }

    func test_signatureOfAnOperatorInAnExtension() {
        XCTAssertNotNil(ArithmeticOperation(
            signature: "static (extension in Foundation):__C.NSDecimal.+ infix(__C.NSDecimal, __C.NSDecimal) -> __C.NSDecimal",
            operator: "+"
        ))
    }

    func test_signaturesThatAreNotArithmetic() {
        XCTAssertNil(ArithmeticOperation(
            signature: "static Swift.String.+ infix(Swift.String, Swift.String) -> Swift.String",
            operator: "+"
        ))
        XCTAssertNil(ArithmeticOperation(
            signature: "static Foundation.Date.+ infix(Foundation.Date, Swift.Double) -> Foundation.Date",
            operator: "+"
        ))
        XCTAssertNil(ArithmeticOperation(
            signature: "static Swift.Numeric.* infix(A, A) -> A",
            operator: "*"
        ))
        XCTAssertNil(ArithmeticOperation(signature: "Fixture.total(Swift.Int, Swift.Int) -> Swift.Int", operator: "+"))
    }

    func test_additiveArithmeticHasOnlyAdditionAndSubtraction() throws {
        let operation = try XCTUnwrap(ArithmeticOperation(
            signature: "static Swift.AdditiveArithmetic.+ infix(A, A) -> A",
            operator: "+"
        ))

        XCTAssertTrue(operation.typeHas("-"))
        XCTAssertFalse(operation.typeHas("/"))
    }

    // MARK: - Helpers

    private func visitor(for code: SourceFileSyntax, index: SymbolIndex?) -> ArithmeticOperatorReplacement.Visitor {
        let visitor = ArithmeticOperatorReplacement.Visitor(
            sourceCodeInfo: SourceCodeInfo(path: sourceFile.path, code: code)
        )
        visitor.symbolIndex = index
        return visitor
    }

    private func mutants(with index: SymbolIndex?) -> [MutationSchema] {
        let code = Parser.parse(source: Self.fixture)
        let visitor = visitor(for: code, index: index)
        visitor.walk(code)
        return visitor.schemataMappings.mutationSchemata
    }

    private func compilerErrors(_ file: URL, arguments: [String]) throws -> String {
        let process = Foundation.Process()
        #if os(macOS)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["swiftc"]
        #else
        process.executableURL = toolchain.tool("swiftc")
        process.arguments = []
        #endif
        process.arguments! += ["-parse-as-library", "-module-name", "Mutated"] + arguments + [file.path]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return String(decoding: data, as: UTF8.self)
            .split(separator: "\n")
            .filter { $0.contains("error:") }
            .joined(separator: "\n")
    }
}
