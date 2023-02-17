import XCTest
import TestingExtensions

@testable import muterCore

final class ChangeLogicalConnectorOperatorTests: XCTestCase {
    private lazy var sourceWithLogicalOperators = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/LogicalOperator/sampleWithLogicalOperators.swift"
    )!
    
    func test_rewriter() throws {
        let visitor = ChangeLogicalConnectorOperator.SchemataVisitor(
            sourceFileInfo: sourceWithLogicalOperators.asSourceFileInfo
        )

        visitor.walk(sourceWithLogicalOperators.code)

        let rewritten = MutationSchemataRewriter(visitor.schemataMappings)
            .visit(sourceWithLogicalOperators.code)

        XCTAssertEqual(
            rewritten.description,
            """
            #if os(iOS) || os(tvOS)
            print("please ignore me")
            #endif

            func someCode() -> Bool { if ProcessInfo.processInfo.environment["sampleWithLogicalOperators_6_18_101"] != nil {
                return false || false
            } else {
                return false && false
            }
            }

            func someOtherCode() -> Bool { if ProcessInfo.processInfo.environment["sampleWithLogicalOperators_10_17_160"] != nil {
                return true && true
            } else {
                return true || true
            }
            }

            """
        )
    }
    
    func test_visitor() throws {
        let visitor = ChangeLogicalConnectorOperator.SchemataVisitor(
            sourceFileInfo: sourceWithLogicalOperators.asSourceFileInfo
        )

        visitor.walk(sourceWithLogicalOperators.code)

        let actualSchematas = visitor.schemataMappings
        let expectedSchematas = try SchemataMutationMapping.make(
            (
                source: "\n    return false && false",
                schematas: [
                    try .make(
                        id: "sampleWithLogicalOperators_10_17_160",
                        filePath: sourceWithLogicalOperators.path,
                        mutationOperatorId: .logicalOperator,
                        syntaxMutation: "\n    return true && true",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 160,
                            line: 10,
                            column: 17
                        ),
                        snapshot: .make(
                            before: "||",
                            after: "&&",
                            description: "changed || to &&"
                        )
                    )
                ]
            ),
            (
                source: "\n    return true || true",
                schematas: [
                    try .make(
                        id: "sampleWithLogicalOperators_6_18_101",
                        filePath: sourceWithLogicalOperators.path,
                        mutationOperatorId: .logicalOperator,
                        syntaxMutation: "\n    return false || false",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 101,
                            line: 6,
                            column: 18
                        ),
                        snapshot: .make(
                            before: "&&",
                            after: "||",
                            description: "changed && to ||"
                        )
                    )
                ]
            )
        )

        XCTAssertEqual(actualSchematas, expectedSchematas)
    }
}
