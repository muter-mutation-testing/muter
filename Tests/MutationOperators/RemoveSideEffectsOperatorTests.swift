@testable import muterCore
import SnapshotTesting
import SwiftSyntax
import TestingExtensions
import XCTest

final class RemoveSideEffectsOperatorTests: MuterTestCase {
    private lazy var sourceWithSideEffects = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithSideEffects.swift"
    )!

    func test_visitor() throws {
        let visitor = RemoveSideEffectsOperator.Visitor(
            sourceCodeInfo: sourceWithSideEffects
        )

        visitor.walk(sourceWithSideEffects.code)

        let actualSchemata = visitor.schemataMappings

        assertMutationPositions(
            actualSchemata, [
                MutationPosition(utf8Offset: 186, line: 10, column: 27),
                MutationPosition(utf8Offset: 423, line: 20, column: 62),
                MutationPosition(utf8Offset: 906, line: 39, column: 6),
                MutationPosition(utf8Offset: 80, line: 3, column: 27),
                MutationPosition(utf8Offset: 994, line: 44, column: 19),
                MutationPosition(utf8Offset: 1049, line: 48, column: 19),
                MutationPosition(utf8Offset: 1099, line: 52, column: 19),
                MutationPosition(utf8Offset: 1138, line: 56, column: 19)
            ]
        )
    }

    func assertMutationPositions(
        _ actual: SchemataMutationMapping,
        _ expected: [MutationPosition],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let actualSorted = actual.mutationSchemata.map(\.position).sorted()
        let expectedSoted = expected.sorted()

        XCTAssertEqual(actualSorted, expectedSoted, file: file, line: line)
    }

    func test_rewriter() throws {
        let visitor = RemoveSideEffectsOperator.Visitor(
            sourceCodeInfo: sourceWithSideEffects
        )

        visitor.walk(sourceWithSideEffects.code)

        let rewriter = MuterRewriter(visitor.schemataMappings, configuration: .init()).rewrite(sourceWithSideEffects.code)

        AssertSnapshot(formatCode(rewriter.description))
    }
}
