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
                        id: "SideEffect_@33_804_6",
                        syntaxMutation: "",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 804,
                            line: 33,
                            column: 6
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
                        id: "SideEffect_@1_16_17",
                        syntaxMutation: "\n        return 1",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 16,
                            line: 1,
                            column: 17
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
                        id: "SideEffect_@16_298_6",
                        syntaxMutation:  "\n        let key = \"some key\"\n        let value = aFunctionThatReturnsAValue()",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 298,
                            line: 16,
                            column: 6
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
                        id: "SideEffect_@5_109_6",
                        syntaxMutation: "\n        print(\"something\")",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 109,
                            line: 5,
                            column: 6
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

        XCTAssertEqual(actualSchematas, expectedSchematas)
    }
    
    func test_rewriter() throws {
        let visitor = RemoveSideEffectsOperator.SchemataVisitor(
            sourceFileInfo: sourceWithSideEffects.asSourceFileInfo
        )

        visitor.walk(sourceWithSideEffects.code)

        let rewritter = Rewriter(visitor.schemataMappings).visit(sourceWithSideEffects.code)

        XCTAssertEqual(
            rewritter.description,
            """
            struct Example {
                func containsSideEffect() -> Int {if ProcessInfo.processInfo.environment["SideEffect_@1_16_17"] != nil {
                    return 1
            } else {
                    _ = causesSideEffect()
                    return 1
            }
                }

                func containsSideEffect() -> Int {if ProcessInfo.processInfo.environment["SideEffect_@5_109_6"] != nil {
                    print("something")
            } else {
                    print("something")

                    _ = causesSideEffect()
            }
                }

                @discardableResult
                func causesSideEffect() -> Int {
                    return 0
                }

                func causesAnotherSideEffect() {if ProcessInfo.processInfo.environment["SideEffect_@16_298_6"] != nil {
                    let key = "some key"
                    let value = aFunctionThatReturnsAValue()
            } else {
                    let key = "some key"
                    let value = aFunctionThatReturnsAValue()
                    someFunctionThatWritesToADatabase(key: key, value: value)
            }
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

                func containsAVoidFunctionCallThatSpansManyLine() {if ProcessInfo.processInfo.environment["SideEffect_@33_804_6"] != nil {
            } else {
                    functionCall("some argument",
                                 anArgumentLabel: "some argument that's different",
                                 anotherArgumentLabel: 5)
            }
                }
            }

            """
        )
    }
}
