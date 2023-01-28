import XCTest
import SwiftSyntax

@testable import muterCore

final class NegateConditionalsOperatorTests: XCTestCase {
    private lazy var sourceWithConditionalLogic = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/sampleWithConditionalOperators.swift"
    )!
    private lazy var sourceWithoutMutableCode = sourceCode(
        fromFileAt: "\(fixturesDirectory)/sourceWithoutMutableCode.swift"
    )!
    private lazy var conditionalConformanceConstraints = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/conditionalConformanceConstraints.swift"
    )!
    
    func test_visitor() {
        let visitor = ROROperator.Visitor(sourceFileInfo: sourceWithConditionalLogic.asSourceFileInfo)
        
        visitor.walk(sourceWithConditionalLogic.code)
        
        guard visitor.positionsOfToken.count == 8 else {
            return XCTFail("Expected 8 tokens to be discovered, got \(visitor.positionsOfToken.count) instead")
        }
        
        XCTAssertEqual(visitor.positionsOfToken[safe: 0]?.line, 3)
        XCTAssertEqual(visitor.positionsOfToken[safe: 1]?.line, 4)
        XCTAssertEqual(visitor.positionsOfToken[safe: 2]?.line, 5)
        XCTAssertEqual(visitor.positionsOfToken[safe: 3]?.line, 6)
        XCTAssertEqual(visitor.positionsOfToken[safe: 4]?.line, 7)
        XCTAssertEqual(visitor.positionsOfToken[safe: 5]?.line, 8)
        XCTAssertEqual(visitor.positionsOfToken[safe: 6]?.line, 10)
        XCTAssertEqual(visitor.positionsOfToken[safe: 7]?.line, 14)
    }
    
    func test_visitorOnFileWithoutOperator() {
        let visitor = ROROperator.Visitor(
            sourceFileInfo: sourceWithoutMutableCode.asSourceFileInfo
        )
        
        visitor.walk(sourceWithoutMutableCode.code)
        
        XCTAssertTrue(visitor.positionsOfToken.isEmpty)
    }
    
    func test_ignoresFunctionDeclarations() {
        let visitor = ROROperator.Visitor(
            sourceFileInfo: sourceWithConditionalLogic.asSourceFileInfo
        )
        
        visitor.walk(sourceWithConditionalLogic.code)

        let functionOperator = visitor.positionsOfToken.first { $0.line == 18 && $0.column == 6 }
        XCTAssertNil(functionOperator)
    }
    
    func test_ignoresConditionalConformancesConstraints() {
        let visitor = ROROperator.Visitor(
            sourceFileInfo: conditionalConformanceConstraints.asSourceFileInfo
        )

        visitor.walk(conditionalConformanceConstraints.code)

        XCTAssertTrue(visitor.positionsOfToken.isEmpty)
    }
    
    func test_rewriter_equalsToNotEquals() {
        let line3Column19 = MutationPosition(utf8Offset: 76, line: 3, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line3Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/equalityOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, "==")
        XCTAssertEqual(rewriter.operatorSnapshot.after, "!=")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed == to !=")
    }
    
    func test_rewriter_notEqualsToEquals() {
        let line4Column19 = MutationPosition(utf8Offset: 99, line: 4, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line4Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/inequalityOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)
        
        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, "!=")
        XCTAssertEqual(rewriter.operatorSnapshot.after, "==")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed != to ==")
    }
    
    func test_rewriter_greaterThanOrEqualToLessThanOrEqual() {
        let line5Column19 = MutationPosition(utf8Offset: 122, line: 5, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line5Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/greaterThanOrEqualOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)
        
        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, ">=")
        XCTAssertEqual(rewriter.operatorSnapshot.after, "<=")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed >= to <=")
    }
    
    func test_rewriter_LessThanOrEqualToGreaterThanOrEqual() {
        let line6Column19 = MutationPosition(utf8Offset: 145, line: 6, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line6Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/lessThanOrEqualOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)
        
        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, "<=")
        XCTAssertEqual(rewriter.operatorSnapshot.after, ">=")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed <= to >=")
    }
    
    func test_rewriter_lessThanToGreaterThan() {
        let line7Column19 = MutationPosition(utf8Offset: 169, line: 7, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line7Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/lessThanOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, "<")
        XCTAssertEqual(rewriter.operatorSnapshot.after, ">")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed < to >")
    }
    
    func test_rewriter_greaterThanToLessThan() {
        let line8Column19 = MutationPosition(utf8Offset: 191, line: 8, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line8Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/greaterThanOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, ">")
        XCTAssertEqual(rewriter.operatorSnapshot.after, "<")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed > to <")
    }
    
    func test_rorTransformation() {
        let line3Column19 = MutationPosition(utf8Offset: 76, line: 3, column: 19)
        sourceWithConditionalLogic = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/sampleWithConditionalOperators.swift"
        )!

        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/equalityOperator.swift"
        )!

        let transformation = MutationOperator.Id.ror.mutationOperator(for: line3Column19)

        let (actualMutatedSource, actualSnapshot) = transformation(sourceWithConditionalLogic.code)
        
        XCTAssertEqual(actualMutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(actualSnapshot.before, "==")
        XCTAssertEqual(actualSnapshot.after, "!=")
        XCTAssertEqual(actualSnapshot.description, "changed == to !=")
    }
}

final class NegateConditionalsOperatorSchemataTests: XCTestCase {
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
        let r = Rewriter(actualSchematas).visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(r.description, "")
//        let expectedSchematas = try SchemataMutationMapping.make(
//            (
//                source: "\n    return false && false",
//                schematas: [
//                    try .make(
//                        id: "LogicalOperator_@10_160_17",
//                        syntaxMutation: "\n    return true && true",
//                        positionInSourceCode: MutationPosition(
//                            utf8Offset: 160,
//                            line: 10,
//                            column: 17
//                        ),
//                        snapshot: .make(
//                            before: "||",
//                            after: "&&",
//                            description: "changed || to &&"
//                        )
//                    )
//                ]
//            )
//        )
//
//        XCTAssertEqual(actualSchematas, expectedSchematas)
    }

    func test_visitorOnFileWithoutOperator() {
        let visitor = ROROperator.Visitor(
            sourceFileInfo: sourceWithoutMutableCode.asSourceFileInfo
        )

        visitor.walk(sourceWithoutMutableCode.code)

        XCTAssertTrue(visitor.positionsOfToken.isEmpty)
    }

    func test_ignoresFunctionDeclarations() {
        let visitor = ROROperator.Visitor(
            sourceFileInfo: sourceWithConditionalLogic.asSourceFileInfo
        )

        visitor.walk(sourceWithConditionalLogic.code)

        let functionOperator = visitor.positionsOfToken.first { $0.line == 18 && $0.column == 6 }
        XCTAssertNil(functionOperator)
    }

    func test_ignoresConditionalConformancesConstraints() {
        let visitor = ROROperator.Visitor(
            sourceFileInfo: conditionalConformanceConstraints.asSourceFileInfo
        )

        visitor.walk(conditionalConformanceConstraints.code)

        XCTAssertTrue(visitor.positionsOfToken.isEmpty)
    }

    func test_rewriter_equalsToNotEquals() {
        let line3Column19 = MutationPosition(utf8Offset: 76, line: 3, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line3Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/equalityOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, "==")
        XCTAssertEqual(rewriter.operatorSnapshot.after, "!=")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed == to !=")
    }

    func test_rewriter_notEqualsToEquals() {
        let line4Column19 = MutationPosition(utf8Offset: 99, line: 4, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line4Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/inequalityOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, "!=")
        XCTAssertEqual(rewriter.operatorSnapshot.after, "==")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed != to ==")
    }

    func test_rewriter_greaterThanOrEqualToLessThanOrEqual() {
        let line5Column19 = MutationPosition(utf8Offset: 122, line: 5, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line5Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/greaterThanOrEqualOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, ">=")
        XCTAssertEqual(rewriter.operatorSnapshot.after, "<=")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed >= to <=")
    }

    func test_rewriter_LessThanOrEqualToGreaterThanOrEqual() {
        let line6Column19 = MutationPosition(utf8Offset: 145, line: 6, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line6Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/lessThanOrEqualOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, "<=")
        XCTAssertEqual(rewriter.operatorSnapshot.after, ">=")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed <= to >=")
    }

    func test_rewriter_lessThanToGreaterThan() {
        let line7Column19 = MutationPosition(utf8Offset: 169, line: 7, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line7Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/lessThanOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, "<")
        XCTAssertEqual(rewriter.operatorSnapshot.after, ">")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed < to >")
    }

    func test_rewriter_greaterThanToLessThan() {
        let line8Column19 = MutationPosition(utf8Offset: 191, line: 8, column: 19)
        let rewriter = ROROperator.Rewriter(positionToMutate: line8Column19)
        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/greaterThanOperator.swift"
        )!

        let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(rewriter.operatorSnapshot.before, ">")
        XCTAssertEqual(rewriter.operatorSnapshot.after, "<")
        XCTAssertEqual(rewriter.operatorSnapshot.description, "changed > to <")
    }

    func test_rorTransformation() {
        let line3Column19 = MutationPosition(utf8Offset: 76, line: 3, column: 19)
        sourceWithConditionalLogic = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/sampleWithConditionalOperators.swift"
        )!

        let expectedSource = sourceCode(
            fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/equalityOperator.swift"
        )!

        let transformation = MutationOperator.Id.ror.mutationOperator(for: line3Column19)

        let (actualMutatedSource, actualSnapshot) = transformation(sourceWithConditionalLogic.code)

        XCTAssertEqual(actualMutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(actualSnapshot.before, "==")
        XCTAssertEqual(actualSnapshot.after, "!=")
        XCTAssertEqual(actualSnapshot.description, "changed == to !=")
    }
}
