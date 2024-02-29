@testable import muterCore
import TestingExtensions
import XCTest

final class SwapTernaryOperatorTests: MuterTestCase {
    private lazy var sampleCode = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/TernaryOperator/sampleWithTernaryOperator.swift"
    )!

    private lazy var sampleNestedCode = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/TernaryOperator/sampleWithNestedTernaryOperator.swift"
    )!

    func test_visitor() throws {
        let visitor = SwapTernaryOperator.Visitor(
            sourceCodeInfo: sampleCode
        )

        visitor.walk(sampleCode.code)

        let actualMappings = visitor.schemataMappings
        let expectedMappings = try SchemataMutationMapping.make(
            filePath: sampleCode.path,
            (
                source: "\n    return a ? \"true\" : \"false\"",
                schemata: [
                    .make(
                        filePath: sampleCode.path,
                        mutationOperatorId: .swapTernary,
                        syntaxMutation: "\n    return a  ? \"false\" :  \"true\" ",
                        position: MutationPosition(
                            utf8Offset: 199,
                            line: 10,
                            column: 32
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: "a ? \"true\" : \"false\"",
                            after: "a  ? \"false\" :  \"true\"",
                            description: "swapped ternary operator"
                        )
                    ),
                ]
            ),
            (
                source: "\n    return a ? true : false",
                schemata: [
                    .make(
                        filePath: sampleCode.path,
                        mutationOperatorId: .swapTernary,
                        syntaxMutation: "\n    return a  ? false :  true ",
                        position: MutationPosition(
                            utf8Offset: 120,
                            line: 6,
                            column: 28
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: "a ? true : false",
                            after: "a  ? false :  true",
                            description: "swapped ternary operator"
                        )
                    ),
                ]
            )
        )

        XCTAssertEqual(actualMappings, expectedMappings)
    }

    func test_visitor_nestedTernaryOperator() throws {
        let visitor = SwapTernaryOperator.Visitor(
            sourceCodeInfo: sampleNestedCode
        )

        visitor.walk(sampleNestedCode.code)

        let actualMappings = visitor.schemataMappings
        let expectedMappings = try SchemataMutationMapping.make(
            (
                source: "\n    return a ? b ? true : false : false",
                schemata: [
                    .make(
                        filePath: sampleNestedCode.path,
                        mutationOperatorId: .swapTernary,
                        syntaxMutation: "\n    return a  ? false :  b ? true : false ",
                        position: MutationPosition(
                            utf8Offset: 143,
                            line: 6,
                            column: 40
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: "a ? b ? true : false : false",
                            after: "a  ? false :  b ? true : false",
                            description: "swapped ternary operator"
                        )
                    ),
                    .make(
                        filePath: sampleNestedCode.path,
                        mutationOperatorId: .swapTernary,
                        syntaxMutation: "\n    return a ? b  ? false :  true : false",
                        position: MutationPosition(
                            utf8Offset: 136,
                            line: 6,
                            column: 33
                        ),
                        snapshot: MutationOperator.Snapshot(
                            before: "b ? true : false",
                            after: "b  ? false :  true",
                            description: "swapped ternary operator"
                        )
                    ),
                ]
            )
        )

        XCTAssertEqual(actualMappings, expectedMappings)
    }

    func test_rewriter() {
        let visitor = SwapTernaryOperator.Visitor(
            sourceCodeInfo: sampleNestedCode
        )

        visitor.walk(sampleNestedCode.code)

        let rewriter = MuterRewriter(visitor.schemataMappings).rewrite(sampleNestedCode.code)

        AssertSnapshot(formatCode(rewriter.description))
    }

    func test_shouldIgnoreComplexExpressions() throws {
        let source = try sourceCode(
            """
            func complexExpression(_ a: Any, _ b: Any) -> Any? {
                return a.isEmpty ? nil : a as [String]
            }
            """
        )

        let visitor = SwapTernaryOperator.Visitor(
            sourceCodeInfo: .init(path: "", code: source)
        )

        visitor.walk(source)

        XCTAssertTrue(visitor.schemataMappings.isEmpty)
    }
}
