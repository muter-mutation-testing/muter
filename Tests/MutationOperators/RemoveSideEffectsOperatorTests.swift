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
        let expectedSchemata = try SchemataMutationMapping.make(
            (
                source: "\n        functionCall(\"some argument\",\n                     anArgumentLabel: \"some argument that\'s different\",\n                     anotherArgumentLabel: 5)",
                schemata: [
                    .make(
                        filePath: sourceWithSideEffects.path,
                        mutationOperatorId: .removeSideEffects,
                        syntaxMutation: "",
                        position: MutationPosition(
                            utf8Offset: 1017,
                            line: 38,
                            column: 46
                        ),
                        snapshot: .make(
                            before: "functionCall(\"some argument\", anArgumentLabel: \"some argument that\'s different\", anotherArgumentLabel: 5)",
                            after: "removed line",
                            description: "removed line"
                        )
                    ),
                ]
            ),
            (
                source: "\n        _ = causesSideEffect()\n        return 1",
                schemata: [
                    .make(
                        filePath: sourceWithSideEffects.path,
                        mutationOperatorId: .removeSideEffects,
                        syntaxMutation: "\n        return 1",
                        position: MutationPosition(
                            utf8Offset: 86,
                            line: 3,
                            column: 31
                        ),
                        snapshot: .make(
                            before: "_ = causesSideEffect()",
                            after: "removed line",
                            description: "removed line"
                        )
                    ),
                ]
            ),
            (
                source: "\n        let key = \"some key\"\n        let value = aFunctionThatReturnsAValue()\n        someFunctionThatWritesToADatabase(key: key, value: value)",
                schemata: [
                    .make(
                        filePath: sourceWithSideEffects.path,
                        mutationOperatorId: .removeSideEffects,
                        syntaxMutation: "\n        let key = \"some key\"\n        let value = aFunctionThatReturnsAValue()",
                        position: MutationPosition(
                            utf8Offset: 480,
                            line: 21,
                            column: 66
                        ),
                        snapshot: .make(
                            before: "someFunctionThatWritesToADatabase(key: key, value: value)",
                            after: "removed line",
                            description: "removed line"
                        )
                    ),
                ]
            ),
            (
                source: "\n        print(\"something\")\n\n        _ = causesSideEffect()",
                schemata: [
                    .make(
                        filePath: sourceWithSideEffects.path,
                        mutationOperatorId: .removeSideEffects,
                        syntaxMutation: "\n        print(\"something\")",
                        position: MutationPosition(
                            utf8Offset: 208,
                            line: 10,
                            column: 31
                        ),
                        snapshot: .make(
                            before: "_ = causesSideEffect()",
                            after: "removed line",
                            description: "removed line"
                        )
                    ),
                ]
            )
        )

        XCTAssertEqual(actualSchemata, expectedSchemata)
    }

    func test_rewriter() throws {
        let visitor = RemoveSideEffectsOperator.Visitor(
            sourceCodeInfo: sourceWithSideEffects
        )

        visitor.walk(sourceWithSideEffects.code)

        let rewriter = MuterRewriter(visitor.schemataMappings).rewrite(sourceWithSideEffects.code)

        AssertSnapshot(rewriter.description)
    }
}
