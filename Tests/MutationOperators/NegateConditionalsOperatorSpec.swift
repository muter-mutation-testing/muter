@testable import muterCore
import Quick
import Nimble
import SwiftSyntax

class NegateConditionalsOperatorSpec: QuickSpec {
    override func spec() {
        describe("") {

            var sourceWithConditionalLogic: SourceFileSyntax!
            var sourceWithoutMuteableCode: SourceFileSyntax!

            beforeEach {
                sourceWithConditionalLogic = sourceCode(fromFileAt: "\(self.fixturesDirectory)/sample.swift")!
                sourceWithoutMuteableCode = sourceCode(fromFileAt: "\(self.fixturesDirectory)/sourceWithoutMuteableCode.swift")!
            }

            describe("NegateConditionalsOperator.Visitor") {
                it("records the positions of code that contains a conditional operator") {
                    let visitor = NegateConditionalsOperator.Visitor()

                    visitor.visit(sourceWithConditionalLogic)

                    guard visitor.positionsOfToken.count == 8 else {
                        fail("Expected 8 tokens to be discovered, got \(visitor.positionsOfToken.count) instead")
                        return
                    }

                    expect(visitor.positionsOfToken[0].line).to(equal(3))
                    expect(visitor.positionsOfToken[1].line).to(equal(4))
                    expect(visitor.positionsOfToken[2].line).to(equal(5))
                    expect(visitor.positionsOfToken[3].line).to(equal(6))
                    expect(visitor.positionsOfToken[4].line).to(equal(7))
                    expect(visitor.positionsOfToken[5].line).to(equal(8))
                    expect(visitor.positionsOfToken[6].line).to(equal(10))
                    expect(visitor.positionsOfToken[7].line).to(equal(14))
                }

                it("records no positions when a file doesn't contain a conditional operator") {
                    let visitor = NegateConditionalsOperator.Visitor()
                    visitor.visit(sourceWithoutMuteableCode)
                    expect(visitor.positionsOfToken).to(haveCount(0))
                }

                it("doesn't discover any mutable positions in function declarations") {
                    
                    let visitor = NegateConditionalsOperator.Visitor()
                    visitor.visit(sourceWithConditionalLogic)
                    
                    let functionOperator = visitor.positionsOfToken.first { $0.line == 18 && $0.column == 6 }
                    expect(functionOperator).to(beNil())
                }
            }

            describe("NegateConditionalsOperator.Rewriter") {
                it("replaces an equality operator with an inequality operator") {
                    let line3Column19 = AbsolutePosition(line: 3, column: 19, utf8Offset: 76)
                    let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: line3Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/equalityOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
                    expect(mutatedSource.description).to(equal(expectedSource.description))
                }

                it("replaces an inequality operator with an equality operator") {
                    let line4Column19 = AbsolutePosition(line: 4, column: 19, utf8Offset: 99)
                    let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: line4Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/inequalityOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
                    expect(mutatedSource.description).to(equal(expectedSource.description))
                }

                it("replaces a greater than or equal to operator with a less than or equal to operator") {
                    let line5Column19 = AbsolutePosition(line: 5, column: 19, utf8Offset: 122)
                    let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: line5Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/greaterThanOrEqualOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
                    expect(mutatedSource.description).to(equal(expectedSource.description))
                }

                it("replaces a less than or equal to operator with a greater than or equal to operator") {
                    let line6Column19 = AbsolutePosition(line: 6, column: 19, utf8Offset: 145)
                    let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: line6Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/lessThanOrEqualOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
                    expect(mutatedSource.description).to(equal(expectedSource.description))
                }

                it("replaces a less than operator with a greater than operator") {
                    let line7Column19 = AbsolutePosition(line: 7, column: 19, utf8Offset: 169)
                    let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: line7Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/lessThanOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
                    expect(mutatedSource.description).to(equal(expectedSource.description))
                }

                it("replaces a greater than operator with a less than operator") {
                    let line8Column19 = AbsolutePosition(line: 8, column: 19, utf8Offset: 191)
                    let rewriter = NegateConditionalsOperator.Rewriter(positionToMutate: line8Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/greaterThanOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
                    expect(mutatedSource.description).to(equal(expectedSource.description))
                }
            }

            describe("MutationOperator.Id.negateConditionals.transformation") {
                it("behaves like a NegateConditionalsOperator.Rewriter") {
                    let line3Column19 = AbsolutePosition(line: 3, column: 19, utf8Offset: 76)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/equalityOperator.swift")!

                    let transformation = MutationOperator.Id.negateConditionals.transformation(for: line3Column19)

                    expect(transformation(sourceWithConditionalLogic).description).to(equal(expectedSource.description))
                }
            }
        }
    }
}
