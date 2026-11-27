@testable import muterCore
import SwiftSyntax
import TestingExtensions
import XCTest

final class MutationRangeTests: MuterTestCase {
    private func ranges(
        _ id: MutationOperator.Id,
        in code: String,
        newLines: Int = 0
    ) throws -> [MutationRange?] {
        let visitor = try walk(id, in: code, newLines: newLines)
        return visitor.schemataMappings.mutationSchemata.map(\.range)
    }

    private func walk(
        _ id: MutationOperator.Id,
        in code: String,
        newLines: Int = 0
    ) throws -> MuterVisitor {
        let source = try sourceCode(code)
        let visitor = id.visitor(nil, SourceCodeInfo(path: "/path/to/file.swift", code: source), [])
        visitor.sourceCodePreparationChange = .init(newLines: newLines)
        visitor.walk(source)
        return visitor
    }

    private func range(_ startLine: Int, _ startColumn: Int, _ endLine: Int, _ endColumn: Int) -> MutationRange {
        MutationRange(
            start: MutationPosition(line: startLine, column: startColumn),
            end: MutationPosition(line: endLine, column: endColumn)
        )
    }

    /// The range covers the changed operator only, not the code block.
    func test_operatorRangeIsTheOperator() throws {
        let ranges = try ranges(.ror, in: """
        func f(a: Int, b: Int) -> Bool {
            return a > b
        }
        """)

        XCTAssertEqual(ranges.map { $0.map(Self.lineAndColumns) }, [Self.lineAndColumns(range(2, 14, 2, 15))])
    }

    func test_ternaryRangeIsTheWholeExpression() throws {
        let ranges = try ranges(.swapTernary, in: """
        func f(a: Bool, b: Int, c: Int) -> Int {
            return a ? b : c
        }
        """)

        XCTAssertEqual(ranges.map { $0.map(Self.lineAndColumns) }, [Self.lineAndColumns(range(2, 12, 2, 21))])
    }

    /// RemoveSideEffects mutates the code block, but the range is the removed statement.
    func test_removedStatementRangeIsTheStatement() throws {
        let ranges = try ranges(.removeSideEffects, in: """
        func f() {
            var values = [Int]()
            values.append(
                1
            )
            print(values)
        }
        """)

        XCTAssertTrue(
            ranges.map { $0.map(Self.lineAndColumns) }.contains(Self.lineAndColumns(range(3, 5, 5, 6))),
            "\(ranges)"
        )
    }

    /// The lines count from the user's file, without the lines that Muter adds before it mutates it.
    func test_rangeLinesLeaveOutTheAddedLines() throws {
        let ranges = try ranges(.ror, in: """
        import Foundation
        // swiftlint:disable all
        func f(a: Int, b: Int) -> Bool {
            return a > b
        }
        """, newLines: 2)

        XCTAssertEqual(ranges.map { $0.map(Self.lineAndColumns) }, [Self.lineAndColumns(range(2, 14, 2, 15))])
    }

    func test_ignoredMutantHasARange() throws {
        let visitor = try walk(.ror, in: """
        func f(a: Int, b: Int) -> Bool {
            // muter:disable next-line
            return a > b
        }
        """)

        XCTAssertEqual(
            visitor.ignoredMutants.map { $0.range.map(Self.lineAndColumns) },
            [Self.lineAndColumns(range(3, 14, 3, 15))]
        )
    }

    /// A range compared by line and column only: the UTF-8 offset is not part of what the reports use.
    private static func lineAndColumns(_ range: MutationRange) -> [Int] {
        [range.start.line, range.start.column, range.end.line, range.end.column]
    }
}
