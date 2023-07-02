import XCTest
import SwiftSyntax
import TestingExtensions

@testable import muterCore

final class RemoveSideEffectsOperatorTests: XCTestCase {
    
    private func applyMutation(
        toFileAt path: String,
        atPosition positionToMutate: MutationPosition,
        expectedOutcome: String
    ) -> (mutatedSource: Syntax, expectedSource: SourceFileSyntax, rewriter: PositionSpecificRewriter) {

        let rewriter = RemoveSideEffectsOperator.Rewriter(positionToMutate: positionToMutate)

        return (
            mutatedSource: Syntax(rewriter.visit(sourceCode(fromFileAt: path)!.code)),
            expectedSource: sourceCode(fromFileAt: expectedOutcome)!.code,
            rewriter
        )
    }
    
    func test_visitor() throws {
        let sourceWithSideEffects = try XCTUnwrap(
            sourceCode(
                fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithSideEffects.swift"
            )
        )

        let visitor = RemoveSideEffectsOperator.Visitor(sourceFileInfo: sourceWithSideEffects.asSourceFileInfo)

        visitor.walk(sourceWithSideEffects.code)

        XCTAssertEqual(visitor.positionsOfToken.count, 4)
        XCTAssertEqual(visitor.positionsOfToken[safe: 0]?.line, 3)
        XCTAssertEqual(visitor.positionsOfToken[safe: 1]?.line, 10)
        XCTAssertEqual(visitor.positionsOfToken[safe: 2]?.line, 21)
        XCTAssertEqual(visitor.positionsOfToken[safe: 3]?.line, 38)
    }
    
    func test_visitor_ignoresPositionsThatDoesNotContainsSideEffects() throws {
        let sourceWithoutSideEffects = try XCTUnwrap(
            sourceCode(
                fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/sampleWithConditionalOperators.swift"
            )
        )

        let visitor = RemoveSideEffectsOperator.Visitor(sourceFileInfo: sourceWithoutSideEffects.asSourceFileInfo)

        visitor.walk(sourceWithoutSideEffects.code)

        XCTAssertTrue(visitor.positionsOfToken.isEmpty)
    }
    
    func test_visitor_ignoresPossibleDeadlockCode() throws {
        let sourceWithConcurrency = try XCTUnwrap(
            sourceCode(
                fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithConcurrency.swift"
            )
        )

        let visitor = RemoveSideEffectsOperator.Visitor(sourceFileInfo: sourceWithConcurrency.asSourceFileInfo)

        visitor.walk(sourceWithConcurrency.code)

        XCTAssertEqual(visitor.positionsOfToken.count, 4)
        XCTAssertEqual(visitor.positionsOfToken[0].line, 10)
        XCTAssertEqual(visitor.positionsOfToken[1].line, 16)
        XCTAssertEqual(visitor.positionsOfToken[2].line, 22)
        XCTAssertEqual(visitor.positionsOfToken[3].line, 28)
    }
    
    func test_visitor_ignoresCallsToExcludedFunctionButNotCallsToOtherFunctionsInIt() throws {
        let sourceWithExcludedFunction = try XCTUnwrap(
            sourceCode(
                fromFileAt: "\(mutationExamplesDirectory)/SideEffect/sampleWithExcludedFunctionCall.swift")
        )

        let visitor = RemoveSideEffectsOperator.Visitor(
            configuration: MuterConfiguration(excludeCallList: ["callExcluded"]),
            sourceFileInfo: sourceWithExcludedFunction.asSourceFileInfo
        )

        visitor.walk(sourceWithExcludedFunction.code)

        XCTAssertEqual(visitor.positionsOfToken.count, 1)
        XCTAssertEqual(visitor.positionsOfToken.first?.line, 3)
    }
    
    func test_visitor_ignoresFunctionsThatAreUsedAsImplicitReturn() throws {
        let sampleWithImplicitReturn = try XCTUnwrap(
            sourceCode(
                fromFileAt: "\(mutationExamplesDirectory)/SideEffect/sampleWithImplicitReturn.swift"
            )
        )
        
        let visitor = RemoveSideEffectsOperator.Visitor(sourceFileInfo: sampleWithImplicitReturn.asSourceFileInfo)
        
        visitor.walk(sampleWithImplicitReturn.code)

        XCTAssertEqual(visitor.positionsOfToken.count, 3)
        XCTAssertEqual(visitor.positionsOfToken[0].line, 2)
        XCTAssertEqual(visitor.positionsOfToken[1].line, 6)
        XCTAssertEqual(visitor.positionsOfToken[2].line, 10)
    }
    
    func test_rewriter_deletesAStatementWithAnExplicitlyDiscardedResult() {
        let path = "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithSideEffects.swift"

        let firstExpectedSource = "\(mutationExamplesDirectory)/SideEffect/removedUnusedReturnResult_line3.swift"
        let secondExpectedSource = "\(mutationExamplesDirectory)/SideEffect/removedUnusedReturnResult_line10.swift"
        let offset86 = MutationPosition(utf8Offset: 86, line: -1, column: -1)
        let offset208 = MutationPosition(utf8Offset: 208, line: -1, column: -1)

        let firstResults = applyMutation(toFileAt: path,
                                         atPosition: offset86,
                                         expectedOutcome: firstExpectedSource)

        let secondResults = applyMutation(toFileAt: path,
                                          atPosition: offset208,
                                          expectedOutcome: secondExpectedSource)

        XCTAssertEqual(firstResults.mutatedSource.description, firstResults.expectedSource.description)
        XCTAssertEqual(secondResults.mutatedSource.description, secondResults.expectedSource.description)
        XCTAssertEqual(firstResults.rewriter.operatorSnapshot.before, "_ = causesSideEffect()")
        XCTAssertEqual(firstResults.rewriter.operatorSnapshot.after, "removed line")
        XCTAssertEqual(firstResults.rewriter.operatorSnapshot.description, "removed line")
        XCTAssertEqual(secondResults.rewriter.operatorSnapshot.before, "_ = causesSideEffect()")
        XCTAssertEqual(secondResults.rewriter.operatorSnapshot.after, "removed line")
        XCTAssertEqual(secondResults.rewriter.operatorSnapshot.description, "removed line")
    }
    
    func test_rewriter_deletesVoidFunctionCallThatSpansOneLine() {
        let path = "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithSideEffects.swift"
        let expectedSourcePath = "\(fixturesDirectory)/MutationExamples/SideEffect/removedVoidFunctionCall_line21.swift"
        let line21 = MutationPosition(utf8Offset: 480, line: -1, column: -1)

        let results = applyMutation(toFileAt: path, atPosition: line21, expectedOutcome: expectedSourcePath)

        XCTAssertEqual(results.mutatedSource.description, results.expectedSource.description)
        XCTAssertEqual(results.rewriter.operatorSnapshot.before, "someFunctionThatWritesToADatabase(key: key, value: value)")
        XCTAssertEqual(results.rewriter.operatorSnapshot.after, "removed line")
    }
    
    func test_rewriter_deletesAVoidFunctionCallThatSpansMultipleLines() {
        let path = "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithSideEffects.swift"
        let expectedSourcePath = "\(fixturesDirectory)/MutationExamples/SideEffect/removedVoidFunctionCall_line36.swift"
        let line38 = MutationPosition(utf8Offset: 1017, line: -1, column: -1)

        let results = applyMutation(toFileAt: path, atPosition: line38, expectedOutcome: expectedSourcePath)

        XCTAssertEqual(results.mutatedSource.description, results.expectedSource.description)
        XCTAssertEqual(results.rewriter.operatorSnapshot.before, "functionCall(\"some argument\", anArgumentLabel: \"some argument that's different\", anotherArgumentLabel: 5)")
        XCTAssertEqual(results.rewriter.operatorSnapshot.after, "removed line")
        XCTAssertEqual(results.rewriter.operatorSnapshot.description, "removed line")
    }
    
    func test_transformation() {
        let sourceWithSideEffects = sourceCode(fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithSideEffects.swift")!
        let expectedSource = sourceCode(fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/removedVoidFunctionCall_line21.swift")!
        let line21 = MutationPosition(utf8Offset: 480, line: 21, column: -1)
        let transformation = MutationOperator.Id.removeSideEffects.mutationOperator(for: line21)

        let (actualMutatedSource, actualSnapshot) = transformation(sourceWithSideEffects.code)
        
        XCTAssertEqual(actualMutatedSource.description, expectedSource.code.description)
        XCTAssertEqual(actualSnapshot.before, "someFunctionThatWritesToADatabase(key: key, value: value)")
        XCTAssertEqual(actualSnapshot.after, "removed line")
        XCTAssertEqual(actualSnapshot.description, "removed line")
    }
}
