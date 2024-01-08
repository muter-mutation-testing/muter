@testable import muterCore
import TestingExtensions
import XCTest

final class ROROperatorTests: MuterTestCase {
    private lazy var sourceWithConditionalLogic = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/sampleWithConditionalOperators.swift"
    )!

    private lazy var sourceWithoutMutableCode = sourceCode(
        fromFileAt: "\(fixturesDirectory)/sourceWithoutMutableCode.swift"
    )!

    private lazy var conditionalConformanceConstraints = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/conditionalConformanceConstraints.swift"
    )!

    func test_visitor() throws {
        let visitor = ROROperator.Visitor(
            sourceCodeInfo: sourceWithConditionalLogic
        )

        visitor.walk(sourceWithConditionalLogic.code)

        let actualSchematas = visitor.schemataMappings
        let expectedMappings = try SchemataMutationMapping.make(
            (
                source: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                schemata: [
                    .make(
                        filePath: sourceWithConditionalLogic.path,
                        mutationOperatorId: .ror,
                        syntaxMutation: "\n        let b = a != 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                        position: MutationPosition(
                            utf8Offset: 76,
                            line: 3,
                            column: 19
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: "==",
                            after: "!=",
                            description: "changed == to !="
                        )
                    ),
                    .make(
                        filePath: sourceWithConditionalLogic.path,
                        mutationOperatorId: .ror,
                        syntaxMutation: "\n        let b = a == 5\n        let e = a == 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                        position: MutationPosition(
                            utf8Offset: 99,
                            line: 4,
                            column: 19
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: "!=",
                            after: "==",
                            description: "changed != to =="
                        )
                    ),
                    .make(
                        filePath: sourceWithConditionalLogic.path,
                        mutationOperatorId: .ror,
                        syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a <= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                        position: MutationPosition(
                            utf8Offset: 122,
                            line: 5,
                            column: 19
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: ">=",
                            after: "<=",
                            description: "changed >= to <="
                        )
                    ),
                    .make(
                        filePath: sourceWithConditionalLogic.path,
                        mutationOperatorId: .ror,
                        syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a >= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                        position: MutationPosition(
                            utf8Offset: 145,
                            line: 6,
                            column: 19
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: "<=",
                            after: ">=",
                            description: "changed <= to >="
                        )
                    ),
                    .make(
                        filePath: sourceWithConditionalLogic.path,
                        mutationOperatorId: .ror,
                        syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a > 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                        position: MutationPosition(
                            utf8Offset: 169,
                            line: 7,
                            column: 19
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: "<",
                            after: ">",
                            description: "changed < to >"
                        )
                    ),
                    .make(
                        filePath: sourceWithConditionalLogic.path,
                        mutationOperatorId: .ror,
                        syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a < 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                        position: MutationPosition(
                            utf8Offset: 191,
                            line: 8,
                            column: 19
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: ">",
                            after: "<",
                            description: "changed > to <"
                        )
                    ),
                    .make(
                        filePath: sourceWithConditionalLogic.path,
                        mutationOperatorId: .ror,
                        syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a != 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                        position: MutationPosition(
                            utf8Offset: 209,
                            line: 10,
                            column: 14
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: "==",
                            after: "!=",
                            description: "changed == to !="
                        )
                    ),
                    .make(
                        filePath: sourceWithConditionalLogic.path,
                        mutationOperatorId: .ror,
                        syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a != 9 ? \"goodbye\" : \"what\"",
                        position: MutationPosition(
                            utf8Offset: 272,
                            line: 14,
                            column: 18
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: "==",
                            after: "!=",
                            description: "changed == to !="
                        )
                    )
                ]
            )
        )

        XCTAssertEqual(actualSchematas, expectedMappings)
    }

    func test_visitorOnFileWithoutOperator() {
        let visitor = ROROperator.Visitor(
            sourceCodeInfo: sourceWithoutMutableCode
        )

        visitor.walk(sourceWithoutMutableCode.code)

        XCTAssertTrue(visitor.schemataMappings.isEmpty)
    }

    func test_ignoresFunctionDeclarations() throws {
        let visitor = ROROperator.Visitor(
            sourceCodeInfo: sourceWithConditionalLogic
        )

        visitor.walk(sourceWithConditionalLogic.code)

        XCTAssertEqual(visitor.schemataMappings.count, 1)
        XCTAssertFalse(visitor.schemataMappings.codeBlocks.contains("func < "))
    }

    func test_ignoresConditionalConformancesConstraints() {
        let visitor = ROROperator.Visitor(
            sourceCodeInfo: conditionalConformanceConstraints
        )

        visitor.walk(conditionalConformanceConstraints.code)

        XCTAssertTrue(visitor.schemataMappings.isEmpty)
    }

    func test_rewriter() {
        let visitor = ROROperator.Visitor(
            sourceCodeInfo: sourceWithConditionalLogic
        )

        visitor.walk(sourceWithConditionalLogic.code)

        let actualSchematas = visitor.schemataMappings
        let rewriter = MuterRewriter(actualSchematas, configuration: .init()).rewrite(sourceWithConditionalLogic.code)

        AssertSnapshot(rewriter.description)
    }
}
