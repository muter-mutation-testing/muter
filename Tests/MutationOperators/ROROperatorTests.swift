import XCTest
import SwiftSyntax

@testable import muterCore

final class ROROperatorTests: XCTestCase {
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
        let visitor = ROROperator.SchemataVisitor(
            sourceFileInfo: sourceWithConditionalLogic.asSourceFileInfo
        )

        visitor.walk(sourceWithConditionalLogic.code)

        let actualSchematas = visitor.schemataMappings
        let expectedMappins = try SchemataMutationMapping.make(
            (
                source: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                schematas: [
                    try .make(
                    id: "NegateConditionals_@3_76_19",
                    syntaxMutation: "\n        let b = a != 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                    positionInSourceCode: MutationPosition(
                        utf8Offset: 76,
                        line: 3,
                        column: 19
                    ),
                    snapshot: MutationOperatorSnapshot(
                        before: "==",
                        after: "!=",
                        description: "changed == to !="
                    )
                ),
                    try .make(
                    id: "NegateConditionals_@4_99_19",
                    syntaxMutation: "\n        let b = a == 5\n        let e = a == 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                    positionInSourceCode: MutationPosition(
                        utf8Offset: 99,
                        line: 4,
                        column: 19
                    ),
                    snapshot: MutationOperatorSnapshot(
                        before: "!=",
                        after: "==",
                        description: "changed != to =="
                    )
                ),
                    try .make(
                    id: "NegateConditionals_@5_122_19",
                    syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a <= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                    positionInSourceCode: MutationPosition(
                        utf8Offset: 122,
                        line: 5,
                        column: 19
                    ),
                    snapshot: MutationOperatorSnapshot(
                        before: ">=",
                        after: "<=",
                        description: "changed >= to <="
                    )
                ),
                    try .make(
                    id: "NegateConditionals_@6_145_19",
                    syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a >= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                    positionInSourceCode: MutationPosition(
                        utf8Offset: 145,
                        line: 6,
                        column: 19
                    ),
                    snapshot: MutationOperatorSnapshot(
                        before: "<=",
                        after: ">=",
                        description: "changed <= to >="
                    )
                ),
                    try .make(
                    id: "NegateConditionals_@7_169_19",
                    syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a > 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                    positionInSourceCode: MutationPosition(
                        utf8Offset: 169,
                        line: 7,
                        column: 19
                    ),
                    snapshot: MutationOperatorSnapshot(
                        before: "<",
                        after: ">",
                        description: "changed < to >"
                    )
                ),
                    try .make(
                    id: "NegateConditionals_@8_191_19",
                    syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a < 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                    positionInSourceCode: MutationPosition(
                        utf8Offset: 191,
                        line: 8,
                        column: 19
                    ),
                    snapshot: MutationOperatorSnapshot(
                        before: ">",
                        after: "<",
                        description: "changed > to <"
                    )
                ),
                    try .make(
                    id: "NegateConditionals_@10_209_14",
                    syntaxMutation: "\n        let b = a != 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                    positionInSourceCode: MutationPosition(
                        utf8Offset: 209,
                        line: 10,
                        column: 14
                    ),
                    snapshot: MutationOperatorSnapshot(
                        before: "==",
                        after: "!=",
                        description: "changed == to !="
                    )
                ),
                    try .make(
                    id: "NegateConditionals_@14_272_18",
                    syntaxMutation: "\n        let b = a != 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                    positionInSourceCode: MutationPosition(
                        utf8Offset: 272,
                        line: 14,
                        column: 18
                    ),
                    snapshot: MutationOperatorSnapshot(
                        before: "==",
                        after: "!=",
                        description: "changed == to !="
                    )
                )]
            )
        )
        
        XCTAssertEqual(actualSchematas, expectedMappins)
    }

    func test_visitorOnFileWithoutOperator() {
        let visitor = ROROperator.SchemataVisitor(
            sourceFileInfo: sourceWithoutMutableCode.asSourceFileInfo
        )

        visitor.walk(sourceWithoutMutableCode.code)

        XCTAssertTrue(visitor.schemataMappings.isEmpty)
    }

    func test_ignoresFunctionDeclarations() throws {
        let visitor = ROROperator.SchemataVisitor(
            sourceFileInfo: sourceWithConditionalLogic.asSourceFileInfo
        )

        visitor.walk(sourceWithConditionalLogic.code)

        XCTAssertEqual(visitor.schemataMappings.count, 1)
        XCTAssertFalse(visitor.schemataMappings.codeBlocks.contains("func < "))
    }

    func test_ignoresConditionalConformancesConstraints() {
        let visitor = ROROperator.SchemataVisitor(
            sourceFileInfo: conditionalConformanceConstraints.asSourceFileInfo
        )

        visitor.walk(conditionalConformanceConstraints.code)

        XCTAssertTrue(visitor.schemataMappings.isEmpty)
    }

    func test_rewriter() {
        let visitor = ROROperator.SchemataVisitor(
            sourceFileInfo: sourceWithConditionalLogic.asSourceFileInfo
        )

        visitor.walk(sourceWithConditionalLogic.code)

        let actualSchematas = visitor.schemataMappings
        let rewriter = Rewriter(actualSchematas).visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(
            rewriter.description,
            """
            struct Example {
                func something(_ a: Int) -> String {if ProcessInfo.processInfo.environment["NegateConditionals_@3_76_19"] != nil {
                    let b = a != 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["NegateConditionals_@14_272_18"] != nil {
                    let b = a != 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["NegateConditionals_@10_209_14"] != nil {
                    let b = a != 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["NegateConditionals_@8_191_19"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a < 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["NegateConditionals_@7_169_19"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a > 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["NegateConditionals_@6_145_19"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a >= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["NegateConditionals_@5_122_19"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a <= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["NegateConditionals_@4_99_19"] != nil {
                    let b = a == 5
                    let e = a == 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            }
                }
            }

            func < (lhs: String, rhs: String) -> Bool {
                return false
            }

            """
        )
    }
}
