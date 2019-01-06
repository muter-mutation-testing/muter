import Foundation
@testable import muterCore
import SwiftSyntax
import XCTest

class BaseNegateConditionalsOperatorTests: XCTestCase {
	var sourceWithConditionalLogic: SourceFileSyntax!
	var sourceWithoutMuteableCode: SourceFileSyntax!
	
	override func setUp() {
		sourceWithConditionalLogic = sourceCode(fromFileAt: "\(fixturesDirectory)/sample.swift")!
		sourceWithoutMuteableCode = sourceCode(fromFileAt: "\(fixturesDirectory)/sourceWithoutMuteableCode.swift")!
	}
}

final class NegateConditionalsOperatorVisitorTests: BaseNegateConditionalsOperatorTests {
	func test_visitorRecordsThePositionsWhereItDiscoversConditionalOperators() {
		let visitor = NegateConditionalsOperator.Visitor()
		
		visitor.visit(sourceWithConditionalLogic)
		
		guard visitor.positionsOfToken.count == 8 else {
			XCTFail("Expected 8 tokens to be discovered, got \(visitor.positionsOfToken) instead")
			return
		}
		
		XCTAssertEqual(visitor.positionsOfToken[0].line, 3)
		XCTAssertEqual(visitor.positionsOfToken[1].line, 4)
		XCTAssertEqual(visitor.positionsOfToken[2].line, 5)
		XCTAssertEqual(visitor.positionsOfToken[3].line, 6)
		XCTAssertEqual(visitor.positionsOfToken[4].line, 7)
		XCTAssertEqual(visitor.positionsOfToken[5].line, 8)
		XCTAssertEqual(visitor.positionsOfToken[6].line, 10)
		XCTAssertEqual(visitor.positionsOfToken[7].line, 14)
	}
	
	func test_visitorRecordsNoPositionsInFilesThatDontContainConditionalOperators() {
		let visitor = NegateConditionalsOperator.Visitor()
		visitor.visit(sourceWithoutMuteableCode)
		XCTAssertEqual(visitor.positionsOfToken.count, 0)
	}
}

final class NegateConditionalsOperatorRewriterTests: BaseNegateConditionalsOperatorTests {
	func test_rewriterReplacesAnEqualityOperatorWithAnInequalityOperator() {
		let positionToMutate = AbsolutePosition(line: 3, column: 19, utf8Offset: 76)
		let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: positionToMutate)
		let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/equalityOperator.swift")!
		
		let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
		XCTAssertEqual(mutatedSource.description, expectedSource.description)
	}
	
	func test_rewriterReplacesAnInequalityOperatorWithAnEqualityOperator() {
		let line4Column19 = AbsolutePosition(line: 4, column: 19, utf8Offset: 99)
		let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: line4Column19)
		let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/inequalityOperator.swift")!
		
		let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
		XCTAssertEqual(mutatedSource.description, expectedSource.description)
	}
	
	func test_rewriterReplacesAGreaterThanOrEqualToOperatorWithALessThanOrEqualToOperator() {
		let line5Column19 = AbsolutePosition(line: 5, column: 19, utf8Offset: 122)
		let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: line5Column19)
		let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/greaterThanOrEqualOperator.swift")!
		
		let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
		XCTAssertEqual(mutatedSource.description, expectedSource.description)
	}
	
	func test_rewriterReplacesALessThanOrEqualToOperatorWithAGreaterThanOrEqualToOperator() {
		let line6Column19 = AbsolutePosition(line: 6, column: 19, utf8Offset: 145)
		let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: line6Column19)
		let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/lessThanOrEqualOperator.swift")!
		
		let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
		XCTAssertEqual(mutatedSource.description, expectedSource.description)
	}
	
	func test_rewriterReplacesALessThanOperatorWithAGreaterThanToOperator() {
		let line7Column19 = AbsolutePosition(line: 7, column: 19, utf8Offset: 169)
		let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: line7Column19)
		let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/lessThanOperator.swift")!
		
		let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
		XCTAssertEqual(mutatedSource.description, expectedSource.description)
	}
	
	func test_rewriterReplacesAGreaterThanOperatorWithALessThanOperator() {
		let line8Column19 = AbsolutePosition(line: 8, column: 19, utf8Offset: 191)
		let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: line8Column19)
		let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/greaterThanOperator.swift")!
		
		let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
		XCTAssertEqual(mutatedSource.description, expectedSource.description)
	}
	
	func test_mutationTransformationBehavesLikeRewriter() {
		let line3Column19 = AbsolutePosition(line: 3, column: 19, utf8Offset: 76)
		let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/equalityOperator.swift")!
		
		let transformation = MutationOperator.Id.negateConditionals.transformation(for: line3Column19)
		
		XCTAssertEqual(transformation(sourceWithConditionalLogic).description, expectedSource.description)
	}
}
