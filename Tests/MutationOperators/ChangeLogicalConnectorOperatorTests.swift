@testable import muterCore
import TestingExtensions
import XCTest

final class ChangeLogicalConnectorOperatorTests: MuterTestCase {
    private lazy var sourceWithLogicalOperators = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/LogicalOperator/sampleWithLogicalOperators.swift".platformNormalizedPath
    )!

    private lazy var sampleWithFailuresParsing = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/LogicalOperator/sampleWithFailuresParsing.swift".platformNormalizedPath
    )!

    func test_rewriter() throws {
        let visitor = ChangeLogicalConnectorOperator.Visitor(
            sourceCodeInfo: sourceWithLogicalOperators
        )

        visitor.walk(sourceWithLogicalOperators.code)

        let rewritten = MuterRewriter(visitor.schemataMappings)
            .rewrite(sourceWithLogicalOperators.code)
        AssertSnapshot(formatCode(rewritten.description))
    }

    func test_visitor() throws {
        let visitor = ChangeLogicalConnectorOperator.Visitor(
            sourceCodeInfo: sourceWithLogicalOperators
        )

        visitor.walk(sourceWithLogicalOperators.code)

        let actualSchemata = visitor.schemataMappings
        let expectedSchemata = try SchemataMutationMapping.make(
            (
                source: "\n    // バルーンの表示判定\n    return false && false",
                schemata: [
                    .make(
                        filePath: sourceWithLogicalOperators.path,
                        mutationOperatorId: .logicalOperator,
                        syntaxMutation: "\n    // バルーンの表示判定\n    return false || false",
                        position: MutationPosition(
                            utf8Offset: 256,
                            line: 15,
                            column: 18
                        ),
                        snapshot: .make(
                            before: "&&",
                            after: "||",
                            description: "changed && to ||"
                        )
                    ),
                ]
            ),
            (
                source: "\n    return false && false",
                schemata: [
                    .make(
                        filePath: sourceWithLogicalOperators.path,
                        mutationOperatorId: .logicalOperator,
                        syntaxMutation: "\n    return true && true",
                        position: MutationPosition(
                            utf8Offset: 160,
                            line: 10,
                            column: 17
                        ),
                        snapshot: .make(
                            before: "||",
                            after: "&&",
                            description: "changed || to &&"
                        )
                    ),
                ]
            ),
            (
                source: "\n    return true || true",
                schemata: [
                    .make(
                        filePath: sourceWithLogicalOperators.path,
                        mutationOperatorId: .logicalOperator,
                        syntaxMutation: "\n    return false || false",
                        position: MutationPosition(
                            utf8Offset: 101,
                            line: 6,
                            column: 18
                        ),
                        snapshot: .make(
                            before: "&&",
                            after: "||",
                            description: "changed && to ||"
                        )
                    ),
                ]
            )
        )

        XCTAssertEqual(actualSchemata, expectedSchemata)
    }

    func test_sampleWithFailuresParsing() throws {
        let visitor = ChangeLogicalConnectorOperator.Visitor(
            sourceCodeInfo: sampleWithFailuresParsing
        )

        visitor.walk(sampleWithFailuresParsing.code)

        let rewritten = MuterRewriter(visitor.schemataMappings)
            .rewrite(sampleWithFailuresParsing.code)
        AssertSnapshot(rewritten.description)
    }
}
