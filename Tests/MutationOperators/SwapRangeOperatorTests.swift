@testable import muterCore
import SwiftSyntax
import TestingExtensions
import XCTest

final class SwapRangeOperatorTests: MuterTestCase {
    private func visit(_ code: String) throws -> (visitor: SwapRangeOperator.Visitor, source: SourceFileSyntax) {
        let source = try sourceCode(code)
        let visitor = SwapRangeOperator.Visitor(
            sourceCodeInfo: SourceCodeInfo(path: "/path/to/file", code: source)
        )
        visitor.walk(source)
        return (visitor, source)
    }

    func test_swapsClosedAndHalfOpenRangesInsideBodies() throws {
        let (visitor, source) = try visit("""
        func load(pageCount: Int) {
            for page in 1...pageCount { print(page) }
            let indices = (0..<pageCount).map { $0 }
            print(indices)
        }
        """)

        XCTAssertEqual(
            visitor.schemataMappings.mutationSchemata.map(\.snapshot.description).sorted(),
            ["changed ... to ..<", "changed ..< to ..."]
        )

        let rewritten = MuterRewriter(visitor.schemataMappings).rewrite(source).description
        XCTAssertTrue(rewritten.contains("for page in 1..<pageCount"), rewritten)
        XCTAssertTrue(rewritten.contains("(0...pageCount)"), rewritten)
    }

    func test_doesNotSwapRangesOutsideABody() throws {
        let (visitor, _) = try visit("""
        let top = 0..<10

        struct Limits {
            static let valid = 1...10
            func page(in range: ClosedRange<Int> = 1...5) {}
        }
        """)

        XCTAssertTrue(visitor.schemataMappings.mutationSchemata.isEmpty)
    }

    func test_doesNotSwapOneSidedRanges() throws {
        // `..<end` and `start...` are prefix and postfix operators, not binary ones.
        let (visitor, _) = try visit("""
        func slices(_ values: [Int], _ end: Int) -> ([Int], [Int]) {
            (Array(values[..<end]), Array(values[end...]))
        }
        """)

        XCTAssertTrue(visitor.schemataMappings.mutationSchemata.isEmpty)
    }
}
