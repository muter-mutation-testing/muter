import XCTest

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
                        id: "sampleWithTernaryOperator_10_32_199",
                        filePath: sampleCode.path,
                        mutationOperatorId: .ternaryOperator,
                        syntaxMutation: "\n    return a ? \"false\" : \"true\"",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 199,
                            line: 10,
                            column: 32
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
                        id: "sampleWithTernaryOperator_6_28_120",
                        filePath: sampleCode.path,
                        mutationOperatorId: .ternaryOperator,
                        syntaxMutation: "\n    return a ? false : true",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 120,
                            line: 6,
                            column: 28
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
                        id: "sampleWithNestedTernaryOperator_6_40_143",
                        filePath: sampleNestedCode.path,
                        mutationOperatorId: .ternaryOperator,
                        syntaxMutation: "\n    return a ? false : b ? true : false",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 143,
                            line: 6,
                            column: 40
                        ),
                        snapshot: MutationOperatorSnapshot(
                            before: "a ? b ? true : false : false",
                            after: "a ? false : b ? true : false",
                            description: "swapped ternary operator"
                        )
                    ),
                    try .make(
                        id: "sampleWithNestedTernaryOperator_6_33_136",
                        filePath: sampleNestedCode.path,
                        mutationOperatorId: .ternaryOperator,
                        syntaxMutation: "\n    return a ? b ? false : true: false",
                        positionInSourceCode: MutationPosition(
                            utf8Offset: 136,
                            line: 6,
                            column: 33
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
        
        let rewriter = MutationSchemataRewriter(visitor.schemataMappings)
            .visit(sampleNestedCode.code)
        
        XCTAssertEqual(
            rewriter.description,
            """
            #if os(iOS) || os(tvOS)
            print("please ignore me")
            #endif

            func someCode(_ a: Bool, _ b: Bool) -> Bool { if ProcessInfo.processInfo.environment["sampleWithNestedTernaryOperator_6_40_143"] != nil {
                return a ? false : b ? true : false
            } else if ProcessInfo.processInfo.environment["sampleWithNestedTernaryOperator_6_33_136"] != nil {
                return a ? b ? false : true: false
            } else {
                return a ? b ? true : false : false
            }
            }

            """
        )
    }
}
