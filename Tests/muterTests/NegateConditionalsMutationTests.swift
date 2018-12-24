import Foundation
@testable import muterCore
import SwiftSyntax
import XCTest

class BaseNegateConditionalsMutationTests: XCTestCase {
    var sourceWithConditionalLogic: SourceFileSyntax!
    var sourceWithoutConditionalLogic: SourceFileSyntax!

    var mutationExamplesDirectory: String {
        return "\(fixturesDirectory)/MutationExamples/NegateConditionals"
    }
}

final class NegateConditionalsMutationTests: BaseNegateConditionalsMutationTests {

    override func setUp() {
        sourceWithConditionalLogic = sourceCode(fromFileAt: "\(fixturesDirectory)/sample.swift")!
        sourceWithoutConditionalLogic = sourceCode(fromFileAt: "\(fixturesDirectory)/sourceWithoutConditionalLogic.swift")!
    }

    func test_negateConditionalsMutation() {
        let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/equalityOperator.swift")!

        let delegateSpy = SourceCodeMutationDelegateSpy()
        let positionToMutate = AbsolutePosition(line: 3, column: 19, utf8Offset: 76)
        let rewriter = NegateConditionalsMutation.Rewriter(positionToMutate: positionToMutate)

        let mutation = NegateConditionalsMutation(filePath: "path",
                                                  sourceCode: sourceWithConditionalLogic,
                                                  rewriter: rewriter,
                                                  delegate: delegateSpy)
        mutation.mutate()

        XCTAssertEqual(delegateSpy.methodCalls, ["writeFile(filePath:contents:)"])
        XCTAssertEqual(delegateSpy.mutatedFileContents.first, expectedSource.description)
        XCTAssertEqual(delegateSpy.mutatedFilePaths.first, "path")
    }

    func test_visitorRecordsThePositionsWhereItDiscoversConditionalOperators() {
        let visitor = NegateConditionalsMutation.Visitor()

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
        let visitor = NegateConditionalsMutation.Visitor()
        visitor.visit(sourceWithoutConditionalLogic)
        XCTAssertEqual(visitor.positionsOfToken.count, 0)
    }

    final class RewriterTests: BaseNegateConditionalsMutationTests {
        override func setUp() {
            sourceWithConditionalLogic = sourceCode(fromFileAt: "\(fixturesDirectory)/sample.swift")!
            sourceWithoutConditionalLogic = sourceCode(fromFileAt: "\(fixturesDirectory)/sourceWithoutConditionalLogic.swift")!
        }

        func test_rewriterReplacesAnEqualityOperatorWithAnInequalityOperator() {
            let positionToMutate = AbsolutePosition(line: 3, column: 19, utf8Offset: 76)
            let rewriter = NegateConditionalsMutation.Rewriter(positionToMutate: positionToMutate)
            let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/equalityOperator.swift")!

            let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
            XCTAssertEqual(mutatedSource.description, expectedSource.description)
        }

        func test_rewriterReplacesAnInequalityOperatorWithAnEqualityOperator() {
            let positionToMutate = AbsolutePosition(line: 4, column: 19, utf8Offset: 99)
            let rewriter = NegateConditionalsMutation.Rewriter(positionToMutate: positionToMutate)
            let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/inequalityOperator.swift")!

            let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
            XCTAssertEqual(mutatedSource.description, expectedSource.description)
        }

        func test_rewriterReplacesAGreaterThanOrEqualToOperatorWithALessThanOrEqualToOperator() {
            let positionToMutate = AbsolutePosition(line: 5, column: 19, utf8Offset: 122)
            let rewriter = NegateConditionalsMutation.Rewriter(positionToMutate: positionToMutate)
            let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/greaterThanOrEqualOperator.swift")!

            let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
            XCTAssertEqual(mutatedSource.description, expectedSource.description)
        }

        func test_rewriterReplacesALessThanOrEqualToOperatorWithAGreaterThanOrEqualToOperator() {
            let positionToMutate = AbsolutePosition(line: 6, column: 19, utf8Offset: 145)
            let rewriter = NegateConditionalsMutation.Rewriter(positionToMutate: positionToMutate)
            let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/lessThanOrEqualOperator.swift")!

            let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
            XCTAssertEqual(mutatedSource.description, expectedSource.description)
        }

        func test_rewriterReplacesALessThanOperatorWithAGreaterThanToOperator() {
            let positionToMutate = AbsolutePosition(line: 7, column: 19, utf8Offset: 169)
            let rewriter = NegateConditionalsMutation.Rewriter(positionToMutate: positionToMutate)
            let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/lessThanOperator.swift")!

            let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
            XCTAssertEqual(mutatedSource.description, expectedSource.description)
        }

        func test_rewriterReplacesAGreaterThanOperatorWithALessThanOperator() {
            let positionToMutate = AbsolutePosition(line: 8, column: 19, utf8Offset: 191)
            let rewriter = NegateConditionalsMutation.Rewriter(positionToMutate: positionToMutate)
            let expectedSource = sourceCode(fromFileAt: "\(mutationExamplesDirectory)/greaterThanOperator.swift")!

            let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
            XCTAssertEqual(mutatedSource.description, expectedSource.description)
        }
    }
}

