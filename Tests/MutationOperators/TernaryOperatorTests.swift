import XCTest
import SwiftSyntax
import SwiftParser

@testable import muterCore

final class TernaryOperatorTests: XCTestCase {
    private lazy var sampleCode = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/TernaryOperator/sampleWithTernaryOperator.swift"
    )!
    private lazy var changedCode = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/TernaryOperator/changedTernaryOperator.swift"
    )!
    private lazy var sampleNestedCode = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/TernaryOperator/sampleWithNestedTernaryOperator.swift"
    )!
    private lazy var changedNestedCode = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/TernaryOperator/changedNestedTernaryOperator.swift"
    )!
    
    func test_visitor() {
        let visitor = TernaryOperator.Visitor(sourceFileInfo: sampleCode.asSourceFileInfo)

        visitor.walk(sampleCode.code)

        XCTAssertEqual(visitor.positionsOfToken.count, 2)

        XCTAssertEqual(visitor.positionsOfToken[safe: 0]?.utf8Offset, 120)
        XCTAssertEqual(visitor.positionsOfToken[safe: 0]?.line, 6)
        XCTAssertEqual(visitor.positionsOfToken[safe: 0]?.column, 28)

        XCTAssertEqual(visitor.positionsOfToken[safe: 1]?.utf8Offset, 199)
        XCTAssertEqual(visitor.positionsOfToken[safe: 1]?.line, 10)
        XCTAssertEqual(visitor.positionsOfToken[safe: 1]?.column, 32)
    }
    
    func test_visitor_nestedTernaryOperator() {
        let visitor = TernaryOperator.Visitor(sourceFileInfo: sampleNestedCode.asSourceFileInfo)

        visitor.walk(sampleNestedCode.code)

        XCTAssertEqual(visitor.positionsOfToken.count, 2)

        XCTAssertEqual(visitor.positionsOfToken[safe: 0]?.utf8Offset, 143)
        XCTAssertEqual(visitor.positionsOfToken[safe: 0]?.line, 6)
        XCTAssertEqual(visitor.positionsOfToken[safe: 0]?.column, 40)

        XCTAssertEqual(visitor.positionsOfToken[safe: 1]?.utf8Offset, 136)
        XCTAssertEqual(visitor.positionsOfToken[safe: 1]?.line, 6)
        XCTAssertEqual(visitor.positionsOfToken[safe: 1]?.column, 33)
    }
    
    func test_rewriter_swapCorrectPositions() {
        let mutationPos = MutationPosition(utf8Offset: 120, line: 6, column: 28)
        let rewriter = TernaryOperator.Rewriter(positionToMutate: mutationPos)

        let mutatedSource = rewriter.visit(sampleCode.code)

        XCTAssertEqual(
            mutatedSource.description,
            changedCode.code.description
        )
    }
    
    func test_rewriter_swapWrongPositions() {
        let mutationPos = MutationPosition(utf8Offset: 0, line: 0, column: 0)
        let rewriter = TernaryOperator.Rewriter(positionToMutate: mutationPos)

        let mutatedSource = rewriter.visit(sampleCode.code)

        XCTAssertEqual(
            mutatedSource.description,
            sampleCode.code.description
        )
    }
    
    func test_rewriter_swapNestedWrongPositions() {
        let mutationPos = MutationPosition(utf8Offset: 136, line: 6, column: 33)
        let rewriter = TernaryOperator.Rewriter(positionToMutate: mutationPos)

        let mutatedSource = rewriter.visit(sampleNestedCode.code)

        XCTAssertEqual(
            mutatedSource.description,
            changedNestedCode.code.description
        )
    }
}
