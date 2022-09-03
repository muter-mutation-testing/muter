@testable import muterCore
import Quick
import Nimble
import SwiftSyntax

class SwapTernaryOperatorSpec: QuickSpec {
    override func spec() {
        describe("") {

            var sampleCode: SourceCodeInfo!
            var changedCode: SourceCodeInfo!
            var sampleNestedCode: SourceCodeInfo!
            var changedNestedCode: SourceCodeInfo!

            beforeEach {
                sampleCode = sourceCode(
                    fromFileAt: "\(self.mutationExamplesDirectory)/TernaryOperator/sampleWithTernaryOperator.swift"
                )!
                changedCode = sourceCode(
                    fromFileAt: "\(self.mutationExamplesDirectory)/TernaryOperator/changedTernaryOperator.swift"
                )!
                sampleNestedCode = sourceCode(
                    fromFileAt: "\(self.mutationExamplesDirectory)/TernaryOperator/sampleWithNestedTernaryOperator.swift"
                )!
                changedNestedCode = sourceCode(
                    fromFileAt: "\(self.mutationExamplesDirectory)/TernaryOperator/changedNestedTernaryOperator.swift"
                )!
            }

            describe("TernaryOperator.Rewriter") {
                
                it("swap expressions of ternary operator with correct position") {
                    let mutationPos = MutationPosition(utf8Offset: 120, line: 6, column: 28)
                    let rewriter = TernaryOperator.Rewriter(positionToMutate: mutationPos)

                    let mutatedSource = rewriter.visit(sampleCode.code)

                    expect(mutatedSource.description).to(equal(changedCode.code.description))
                }
                
                it("swap expressions of ternary operator with wrong position") {
                    let mutationPos = MutationPosition(utf8Offset: 0, line: 0, column: 0)
                    let rewriter = TernaryOperator.Rewriter(positionToMutate: mutationPos)

                    let mutatedSource = rewriter.visit(sampleCode.code)

                    expect(mutatedSource.description).to(equal(sampleCode.code.description))
                }
                
                it("swap expressions of nested ternary operator with wrong position") {
                    let mutationPos = MutationPosition(utf8Offset: 136, line: 6, column: 33)
                    let rewriter = TernaryOperator.Rewriter(positionToMutate: mutationPos)

                    let mutatedSource = rewriter.visit(sampleNestedCode.code)

                    expect(mutatedSource.description).to(equal(changedNestedCode.code.description))
                }
            }
            
            describe("TernaryOperator.Visitor") {
                it("records the positions of code that contains a ternary operator") {

                    let visitor = TernaryOperator.Visitor(sourceFileInfo: sampleCode.asSourceFileInfo)
                    
                    visitor.walk(sampleCode.code)

                    expect(visitor.positionsOfToken.count).to(equal(2))
                    
                    expect(visitor.positionsOfToken[0].utf8Offset).to(equal(120))
                    expect(visitor.positionsOfToken[0].line).to(equal(6))
                    expect(visitor.positionsOfToken[0].column).to(equal(28))
                    
                    expect(visitor.positionsOfToken[1].utf8Offset).to(equal(199))
                    expect(visitor.positionsOfToken[1].line).to(equal(10))
                    expect(visitor.positionsOfToken[1].column).to(equal(32))
                }
                
                it("records the positions of code that contains a nested ternary operator") {

                    let visitor = TernaryOperator.Visitor(sourceFileInfo: sampleNestedCode.asSourceFileInfo)
                    
                    visitor.walk(sampleNestedCode.code)

                    expect(visitor.positionsOfToken.count).to(equal(2))
                    
                    expect(visitor.positionsOfToken[0].utf8Offset).to(equal(143))
                    expect(visitor.positionsOfToken[0].line).to(equal(6))
                    expect(visitor.positionsOfToken[0].column).to(equal(40))
                    
                    expect(visitor.positionsOfToken[1].utf8Offset).to(equal(136))
                    expect(visitor.positionsOfToken[1].line).to(equal(6))
                    expect(visitor.positionsOfToken[1].column).to(equal(33))
                }
            }
        }
    }
}
