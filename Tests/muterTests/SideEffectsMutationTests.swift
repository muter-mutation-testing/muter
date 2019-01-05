import class Foundation.Bundle
import SwiftSyntax
@testable import muterCore
import XCTest

final class SideEffectsMutationVisitorTests: XCTestCase {
	func test_visitorRecordsThePositionsWhereItDiscoversSideEffectsBeingCaused() {
		let sourceWithSideEffects = sourceCode(fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/unusedReturnResult.swift")!
		
		let visitor = SideEffectsMutation.Visitor()
		visitor.visit(sourceWithSideEffects)
		
		guard visitor.positionsOfToken.count == 3 else {
			XCTFail("Expected 3 tokens to be discovered, got \(visitor.positionsOfToken.count) instead")
			return
		}
		
		XCTAssertEqual(visitor.positionsOfToken[0].line, 3)
		XCTAssertEqual(visitor.positionsOfToken[1].line, 10)
		XCTAssertEqual(visitor.positionsOfToken[2].line, 21)
	}
	
	func test_visitorRecordsNoPositionsInFilesThatDontContainSideEffectCausingCode() {
		let sourceWithoutSideEffects = sourceCode(fromFileAt: "\(fixturesDirectory)/sample.swift")!
		
		let visitor = SideEffectsMutation.Visitor()
		visitor.visit(sourceWithoutSideEffects)
		
		XCTAssertEqual(visitor.positionsOfToken.count, 0)
	}
}

class SideEffectsMutationRewriterTests: XCTestCase {
	func test_rewriterDeletesAStatementWithAnIgnoredDiscardableResult() {
		
		let path = "\(fixturesDirectory)/MutationExamples/SideEffect/unusedReturnResult.swift"
		
		let firstExpectedSource = "\(mutationExamplesDirectory)/SideEffect/removedUnusedReturnResult_line3.swift"
		let secondExpectedSource = "\(mutationExamplesDirectory)/SideEffect/removedUnusedReturnResult_line10.swift"
		let line3 = AbsolutePosition(line: 3, column: -1, utf8Offset: -1)
		let line10 = AbsolutePosition(line: 10, column: -1, utf8Offset: -1)
		
		let firstResults = applyMutation(toFileAt: path,
										 atPosition: line3,
										 expectedOutcome: firstExpectedSource)
		
		let secondResults = applyMutation(toFileAt: path,
										  atPosition: line10,
										  expectedOutcome: secondExpectedSource)
		
		XCTAssertEqual(firstResults.mutatedSource.description, firstResults.expectedSource.description)
		XCTAssertEqual(secondResults.mutatedSource.description, secondResults.expectedSource.description)
	}
	
	func test_rewriterDeletesAVoidFunctionCall() {
		let path = "\(fixturesDirectory)/MutationExamples/SideEffect/unusedReturnResult.swift"
		let expectedSourcePath = "\(fixturesDirectory)/MutationExamples/SideEffect/removedVoidFunctionCall_line21.swift"
		let line21 = AbsolutePosition(line: 21, column: -1, utf8Offset: -1)
		
		let results = applyMutation(toFileAt: path, atPosition: line21, expectedOutcome: expectedSourcePath)
		
		XCTAssertEqual(results.mutatedSource.description, results.expectedSource.description)
	}
	
	func test_mutationTransformationBehavesLikeRewriter() {
		let sourceWithSideEffects = sourceCode(fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/unusedReturnResult.swift")!
		let expectedSource = sourceCode(fromFileAt:  "\(fixturesDirectory)/MutationExamples/SideEffect/removedVoidFunctionCall_line21.swift")!
		let line21 = AbsolutePosition(line: 21, column: -1, utf8Offset: -1)
		
		let transformation = MutationOperator.Id.sideEffects.transformation(for: line21)
		
		XCTAssertEqual(transformation(sourceWithSideEffects).description, expectedSource.description)
	}
	
	private func applyMutation(toFileAt path: String, atPosition positionToMutate: AbsolutePosition, expectedOutcome: String) -> (mutatedSource: Syntax, expectedSource: Syntax) {
		
		let rewriter = SideEffectsMutation.Rewriter(positionToMutate: positionToMutate)
		
		return (
			mutatedSource: rewriter.visit(sourceCode(fromFileAt: path)!),
			expectedSource: sourceCode(fromFileAt: expectedOutcome)!
		)
	}
}

