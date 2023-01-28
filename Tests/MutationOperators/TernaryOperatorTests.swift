import XCTest
import SwiftSyntax

@testable import muterCore

final class TernaryOperatorTests: XCTestCase {
    private lazy var sampleCode = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/TernaryOperator/sampleWithTernaryOperator.swift"
    )!

    private lazy var sampleNestedCode = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/TernaryOperator/sampleWithNestedTernaryOperator.swift"
    )!
    
    func test_visitor() throws {
        let visitor = TernaryOperator.SchemataVisitor(
            sourceFileInfo: sampleCode.asSourceFileInfo
        )

        visitor.walk(sampleCode.code)

        let actualMappings = visitor.schemataMappings
        let expectedMappings = try SchemataMutationMapping.make(
            (
                source: "\n    return a ? \"true\" : \"false\"",
                schematas: [
                    try .make(
                        id: "TernaryOperator_@10_179_12",
                        syntaxMutation: "\n    return a ? \"false\" : \"true\"",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 179,
                            line: 10,
                            column: 12
                        ),
                        snapshot: MutationOperatorSnapshot(
                            before: "a ? \"true\" : \"false\"",
                            after: "a ? \"false\" : \"true\"",
                            description: "swapped ternary operator"
                        )
                    )
                ]
            ),
            (
                source: "\n    return a ? true : false",
                schematas: [
                    try .make(
                        id: "TernaryOperator_@6_104_12",
                        syntaxMutation: "\n    return a ? false : true",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 104,
                            line: 6,
                            column: 12
                        ),
                        snapshot: MutationOperatorSnapshot(
                            before: "a ? true : false",
                            after: "a ? false : true",
                            description: "swapped ternary operator"
                        )
                    )
                ]
            )
        )

        XCTAssertEqual(actualMappings, expectedMappings)
    }
    
    func test_visitor_nestedTernaryOperator() throws {
        let visitor = TernaryOperator.SchemataVisitor(
            sourceFileInfo: sampleNestedCode.asSourceFileInfo
        )
        
        visitor.walk(sampleNestedCode.code)
        
        let actualMappings = visitor.schemataMappings
        let expectedMappings = try SchemataMutationMapping.make(
            (
                source: "\n    return a ? b ? true : false : false",
                schematas: [
                    try .make(
                        id: "TernaryOperator_@6_115_12",
                        syntaxMutation: "\n    return a ? false : b ? true : false",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 115,
                            line: 6,
                            column: 12
                        ),
                        snapshot: MutationOperatorSnapshot(
                            before: "a ? b ? true : false : false",
                            after: "a ? false : b ? true : false",
                            description: "swapped ternary operator"
                        )
                    ),
                    try .make(
                        id: "TernaryOperator_@6_119_16",
                        syntaxMutation: "\n    return a ? b ? false : true: false",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 119,
                            line: 6,
                            column: 16
                        ),
                        snapshot: MutationOperatorSnapshot(
                            before: "b ? true : false",
                            after: "b ? false : true",
                            description: "swapped ternary operator"
                        )
                    )
                ]
            )
        )

        XCTAssertEqual(actualMappings, expectedMappings)
    }
    
    func test_rewriter() {
        let visitor = TernaryOperator.SchemataVisitor(
            sourceFileInfo: sampleNestedCode.asSourceFileInfo
        )
        
        visitor.walk(sampleNestedCode.code)
        
        let rewritter = Rewriter(visitor.schemataMappings).visit(sampleNestedCode.code)
        
        XCTAssertEqual(
            rewritter.description,
            """
            #if os(iOS) || os(tvOS)
            print("please ignore me")
            #endif

            func someCode(_ a: Bool, _ b: Bool) -> Bool {if ProcessInfo.processInfo.environment["TernaryOperator_@6_115_12"] != nil {
                return a ? false : b ? true : false
            } else if ProcessInfo.processInfo.environment["TernaryOperator_@6_119_16"] != nil {
                return a ? b ? false : true: false
            } else {
                return a ? b ? true : false : false
            }
            }

            """
        )
    }
}
