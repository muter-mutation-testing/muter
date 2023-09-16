@testable import muterCore
import SwiftSyntax
import TestingExtensions
import XCTest

final class RemoveSideEffectsOperatorTests: MuterTestCase {
    private lazy var sourceWithSideEffects = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithSideEffects.swift"
    )!

    func test_visitor() throws {
        let visitor = RemoveSideEffectsOperator.Visitor(
            sourceFileInfo: sourceWithSideEffects.asSourceFileInfo
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
                    )
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
                    )
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
                    )
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
                    )
                ]
            )
        )

        XCTAssertEqual(actualSchemata, expectedSchemata)
    }

    func test_rewriter() throws {
        let visitor = RemoveSideEffectsOperator.Visitor(
            sourceFileInfo: sourceWithSideEffects.asSourceFileInfo
        )

        visitor.walk(sourceWithSideEffects.code)

        let rewriter = MuterRewriter(visitor.schemataMappings).visit(sourceWithSideEffects.code)

        XCTAssertEqual(
            rewriter.description,
            """
            struct Example {
                func containsSideEffect() -> Int { if ProcessInfo.processInfo.environment["sampleWithSideEffects_3_31_86"] != nil {
                    return 1
            } else {
                    _ = causesSideEffect()
                    return 1
            }
                }

                func containsSideEffect() -> Int { if ProcessInfo.processInfo.environment["sampleWithSideEffects_10_31_208"] != nil {
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

                func causesAnotherSideEffect() { if ProcessInfo.processInfo.environment["sampleWithSideEffects_21_66_480"] != nil {
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

                func containsAVoidFunctionCallThatSpansManyLine() { if ProcessInfo.processInfo.environment["sampleWithSideEffects_38_46_1017"] != nil {
            } else {
            return functionCall("some argument",
                                 anArgumentLabel: "some argument that's different",
                                 anotherArgumentLabel: 5)
            }
                }
            }

            """
        )
    }
}
