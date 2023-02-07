import XCTest
import SwiftSyntax
import SwiftSyntaxParser

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

        let rewritten = Rewriter(visitor.schemataMappings)
            .visit(sourceWithLogicalOperators.code)

        XCTAssertEqual(
            rewritten.description,
            """
            import Foundation
            #if os(iOS) || os(tvOS)
            print("please ignore me")
            #endif

            func someCode() -> Bool {
                return false && false
            }

            func someOtherCode() -> Bool {
                return true || true
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
                        id: "LogicalOperator_@10_160_17",
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
                        id: "LogicalOperator_@6_101_18",
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
