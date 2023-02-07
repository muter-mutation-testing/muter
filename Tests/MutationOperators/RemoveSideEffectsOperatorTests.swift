import XCTest
import SwiftSyntax
import TestingExtensions

@testable import muterCore

final class RemoveSideEffectsOperatorTests: XCTestCase {
    private lazy var sourceWithSideEffects = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithSideEffects.swift"
    )!

    func test_visitor() throws {
        let visitor = RemoveSideEffectsOperator.SchemataVisitor(
            sourceFileInfo: sourceWithSideEffects.asSourceFileInfo
        )

        visitor.walk(sourceWithSideEffects.code)

        let actualSchematas = visitor.schemataMappings
        let expectedSchematas = try SchemataMutationMapping.make(
            (
                source: "\n        functionCall(\"some argument\",\n                     anArgumentLabel: \"some argument that\'s different\",\n                     anotherArgumentLabel: 5)",
                schematas: [
                    try .make(
                        id: "SideEffect_@38_1017_46",
                        syntaxMutation: "",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 1017,
                            line: 38,
                            column: 46
                        ),
                        snapshot: .make(
                            before: "functionCall(\"some argument\", anArgumentLabel: \"some argument that\'s different\", anotherArgumentLabel: 5)",
                            after: "removed line",
                            description: "removed line"
                        )
                    )
                ]
            ),
            (
                source: "\n        _ = causesSideEffect()\n        return 1",
                schematas: [
                    try .make(
                        id: "SideEffect_@3_86_31",
                        syntaxMutation: "\n        return 1",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 86,
                            line: 3,
                            column: 31
                        ),
                        snapshot: .make(
                            before: "_ = causesSideEffect()",
                            after: "removed line",
                            description: "removed line"
                        )
                    )
                ]
            ),
            (
                source: "\n        let key = \"some key\"\n        let value = aFunctionThatReturnsAValue()\n        someFunctionThatWritesToADatabase(key: key, value: value)",
                schematas: [
                    try .make(
                        id: "SideEffect_@21_480_66",
                        syntaxMutation:  "\n        let key = \"some key\"\n        let value = aFunctionThatReturnsAValue()",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 480,
                            line: 21,
                            column: 66
                        ),
                        snapshot: .make(
                            before: "someFunctionThatWritesToADatabase(key: key, value: value)",
                            after: "removed line",
                            description: "removed line"
                        )
                    )
                ]
            ),
            (
                source: "\n        print(\"something\")\n\n        _ = causesSideEffect()",
                schematas: [
                    try .make(
                        id: "SideEffect_@10_208_31",
                        syntaxMutation: "\n        print(\"something\")",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 208,
                            line: 10,
                            column: 31
                        ),
                        snapshot: .make(
                            before: "_ = causesSideEffect()",
                            after: "removed line",
                            description: "removed line"
                        )
                    )
                ]
            )
        )

        print(actualSchematas)
        XCTAssertEqual(actualSchematas, expectedSchematas)
    }
    
    func test_rewriter() throws {
        let visitor = RemoveSideEffectsOperator.SchemataVisitor(
            sourceFileInfo: sourceWithSideEffects.asSourceFileInfo
        )

        visitor.walk(sourceWithSideEffects.code)

        let rewriter = Rewriter(visitor.schemataMappings).visit(sourceWithSideEffects.code)

        XCTAssertEqual(
            rewriter.description,
            """
            import Foundation
            struct Example {
                func containsSideEffect() -> Int {
                    _ = causesSideEffect()
                    return 1
                }

                func containsSideEffect() -> Int {
                    print("something")

                    _ = causesSideEffect()
                }

                @discardableResult
                func causesSideEffect() -> Int {
                    return 0
                }

                func causesAnotherSideEffect() {
                    let key = "some key"
                    let value = aFunctionThatReturnsAValue()
                    someFunctionThatWritesToADatabase(key: key, value: value)
                }

                func containsSpecialCases() {
                    fatalError("this should never be deleted!")
                    exit(1)
                    abort()
                }

                func containsADeepMethodCall() {
                    let containsIgnoredResult = statement.description.contains("_ = ")
                    var anotherIgnoredResult = statement.description.contains("_ = ")
                }

                func containsAVoidFunctionCallThatSpansManyLine() {
                    functionCall("some argument",
                                 anArgumentLabel: "some argument that's different",
                                 anotherArgumentLabel: 5)
                }
            }


            """
        )
    }
}
