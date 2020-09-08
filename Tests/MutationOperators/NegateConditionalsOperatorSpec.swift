@testable import muterCore
import Quick
import Nimble
import SwiftSyntax

class NegateConditionalsOperatorSpec: QuickSpec {
    override func spec() {
        describe("") {

            var sourceWithConditionalLogic: (code: SourceFileSyntax, path: String)!
            var sourceWithoutMuteableCode: (code: SourceFileSyntax, path: String)!
            var conditionalConformanceConstraints: (code: SourceFileSyntax, path: String)!

            beforeEach {
                sourceWithConditionalLogic = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/sampleWithConditionalOperators.swift")!
                sourceWithoutMuteableCode = sourceCode(fromFileAt: "\(self.fixturesDirectory)/sourceWithoutMuteableCode.swift")!
                conditionalConformanceConstraints = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/conditionalConformanceConstraints.swift")!
            }

            describe("NegateConditionalsOperator.Visitor") {
                it("records the positions of code that contains a conditional operator") {
                    let visitor = ROROperator.Visitor(file: sourceWithConditionalLogic.path, source: sourceWithConditionalLogic.code.description)

                    visitor.walk(sourceWithConditionalLogic.code)

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
                    let visitor = ROROperator.Visitor(file: sourceWithoutMuteableCode.path, source: sourceWithoutMuteableCode.code.description)
                    visitor.walk(sourceWithoutMuteableCode.code)
                    expect(visitor.positionsOfToken).to(haveCount(0))
                }

                it("doesn't discover any mutable positions in function declarations") {

                    let visitor = ROROperator.Visitor(file: sourceWithConditionalLogic.path, source: sourceWithConditionalLogic.code.description)
                    visitor.walk(sourceWithConditionalLogic.code)

                    let functionOperator = visitor.positionsOfToken.first { $0.line == 18 && $0.column == 6 }
                    expect(functionOperator).to(beNil())
                }

                it("doesn't discover any mutable positions in conditional conformance constraints") {

                    let visitor = ROROperator.Visitor(file: conditionalConformanceConstraints.path, source: conditionalConformanceConstraints.code.description)
                    visitor.walk(conditionalConformanceConstraints.code)

                    expect(visitor.positionsOfToken).to(beEmpty())
                }
            }

            describe("NegateConditionalsOperator.Rewriter") {
                it("replaces an equality operator with an inequality operator") {
                    let line3Column19 = MutationPosition(utf8Offset: 76, line: 3, column: 19)
                    let rewriter = ROROperator.Rewriter(positionToMutate: line3Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/equalityOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)
                    expect(mutatedSource.description).to(equal(expectedSource.code.description))
                    expect(rewriter.description).to(equal("changed == to !="))
                }

                it("replaces an inequality operator with an equality operator") {
                    let line4Column19 = MutationPosition(utf8Offset: 99, line: 4, column: 19)
                    let rewriter = ROROperator.Rewriter(positionToMutate: line4Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/inequalityOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)
                    expect(mutatedSource.description).to(equal(expectedSource.code.description))
                    expect(rewriter.description).to(equal("changed != to =="))
                }

                it("replaces a greater than or equal to operator with a less than or equal to operator") {
                    let line5Column19 = MutationPosition(utf8Offset: 122, line: 5, column: 19)
                    let rewriter = ROROperator.Rewriter(positionToMutate: line5Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/greaterThanOrEqualOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)
                    expect(mutatedSource.description).to(equal(expectedSource.code.description))
                    expect(rewriter.description).to(equal("changed >= to <="))
                }

                it("replaces a less than or equal to operator with a greater than or equal to operator") {
                    let line6Column19 = MutationPosition(utf8Offset: 145, line: 6, column: 19)
                    let rewriter = ROROperator.Rewriter(positionToMutate: line6Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/lessThanOrEqualOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)
                    expect(mutatedSource.description).to(equal(expectedSource.code.description))
                    expect(rewriter.description).to(equal("changed <= to >="))
                }

                it("replaces a less than operator with a greater than operator") {
                    let line7Column19 = MutationPosition(utf8Offset: 169, line: 7, column: 19)
                    let rewriter = ROROperator.Rewriter(positionToMutate: line7Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/lessThanOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)
                    expect(mutatedSource.description).to(equal(expectedSource.code.description))
                    expect(rewriter.description).to(equal("changed < to >"))
                }

                it("replaces a greater than operator with a less than operator") {
                    let line8Column19 = MutationPosition(utf8Offset: 191, line: 8, column: 19)
                    let rewriter = ROROperator.Rewriter(positionToMutate: line8Column19)
                    let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/greaterThanOperator.swift")!

                    let mutatedSource = rewriter.visit(sourceWithConditionalLogic.code)
                    expect(mutatedSource.description).to(equal(expectedSource.code.description))
                    expect(rewriter.description).to(equal("changed > to <"))
                }
            }

            describe("MutationOperator.Id.ror.transformation") {
                let line3Column19 = MutationPosition(utf8Offset: 76, line: 3, column: 19)
                sourceWithConditionalLogic = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/sampleWithConditionalOperators.swift")!
                let expectedSource = sourceCode(fromFileAt: "\(self.mutationExamplesDirectory)/NegateConditionals/equalityOperator.swift")!
                let transformation = MutationOperator.Id.ror.mutationOperator(for: line3Column19)

                let (actualMutatedSource, actualDescription) = transformation(sourceWithConditionalLogic.code)

                it("behaves like a NegateConditionalsOperator.Rewriter") {
                    expect(actualMutatedSource.description).to(equal(expectedSource.code.description))
                }

                it("provides a description of the operator that was applied") {
                    expect(actualDescription).to(equal("changed == to !="))
                }
            }
        }
    }
}
