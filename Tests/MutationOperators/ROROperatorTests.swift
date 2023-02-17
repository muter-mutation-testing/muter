import XCTest

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
        let expectedMappings = try SchemataMutationMapping.make(
            (
                source: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
                schematas: [
                    try .make(
                    id: "sampleWithConditionalOperators_3_19_76",
                    filePath: sourceWithConditionalLogic.path,
                    mutationOperatorId: .ror,
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
                    id: "sampleWithConditionalOperators_4_19_99",
                    filePath: sourceWithConditionalLogic.path,
                    mutationOperatorId: .ror,
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
                    id: "sampleWithConditionalOperators_5_19_122",
                    filePath: sourceWithConditionalLogic.path,
                    mutationOperatorId: .ror,
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
                    id: "sampleWithConditionalOperators_6_19_145",
                    filePath: sourceWithConditionalLogic.path,
                    mutationOperatorId: .ror,
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
                    id: "sampleWithConditionalOperators_7_19_169",
                    filePath: sourceWithConditionalLogic.path,
                    mutationOperatorId: .ror,
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
                    id: "sampleWithConditionalOperators_8_19_191",
                    filePath: sourceWithConditionalLogic.path,
                    mutationOperatorId: .ror,
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
                    id: "sampleWithConditionalOperators_10_14_209",
                    filePath: sourceWithConditionalLogic.path,
                    mutationOperatorId: .ror,
                    syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a != 10 {\n            return \"hello\"\n        }\n\n        return a == 9 ? \"goodbye\" : \"what\"",
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
                    id: "sampleWithConditionalOperators_14_18_272",
                    filePath: sourceWithConditionalLogic.path,
                    mutationOperatorId: .ror,
                    syntaxMutation: "\n        let b = a == 5\n        let e = a != 1\n        let c = a >= 4\n        let d = a <= 10\n        let f = a < 5\n        let g = a > 5\n\n        if a == 10 {\n            return \"hello\"\n        }\n\n        return a != 9 ? \"goodbye\" : \"what\"",
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

        XCTAssertEqual(actualSchematas, expectedMappings)
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
        let rewriter = MutationSchemataRewriter(actualSchematas).visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(
            rewriter.description,
            """
            struct Example {
                func something(_ a: Int) -> String { if ProcessInfo.processInfo.environment["sampleWithConditionalOperators_3_19_76"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithConditionalOperators_14_18_272"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a == 10 {
                        return "hello"
                    }

                    return a != 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["sampleWithConditionalOperators_10_14_209"] != nil {
                    let b = a == 5
                    let e = a != 1
                    let c = a >= 4
                    let d = a <= 10
                    let f = a < 5
                    let g = a > 5

                    if a != 10 {
                        return "hello"
                    }

                    return a == 9 ? "goodbye" : "what"
            } else if ProcessInfo.processInfo.environment["sampleWithConditionalOperators_8_19_191"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithConditionalOperators_7_19_169"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithConditionalOperators_6_19_145"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithConditionalOperators_5_19_122"] != nil {
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
            } else if ProcessInfo.processInfo.environment["sampleWithConditionalOperators_4_19_99"] != nil {
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
