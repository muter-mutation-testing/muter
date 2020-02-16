import Quick
import Nimble
import SwiftSyntax
@testable import muterCore

class ChangeLogicalConnectorOperatorSpec: QuickSpec {
    override func spec() {
        describe("") {
            let sourceWithLogicalOperators = sourceCode(fromFileAt: "\(self.fixturesDirectory)/MutationExamples/LogicalOperator/sampleWithLogicalOperators.swift")!
            
            describe("LogicalOperator.Rewriter") {
                
                it("converts a && operator to a || operator") {
                    let line2Column18 = AbsolutePosition(line: 2, column: 18, utf8Offset: 43)
                    let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/MutationExamples/LogicalOperator/changedANDOperator.swift")!
                    
                    let rewriter = ChangeLogicalConnectorOperator.Rewriter(positionToMutate: line2Column18)
                    let mutatedSource = rewriter.visit(sourceWithLogicalOperators)
                    
                    expect(mutatedSource.description) == expectedSource.description
                }
                
                it("converts a || operator to a && operator") {
                    let line6Column17 = AbsolutePosition(line: 6, column: 17, utf8Offset: 102)
                    let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/MutationExamples/LogicalOperator/changedOROperator.swift")!
                    
                    let rewriter = ChangeLogicalConnectorOperator.Rewriter(positionToMutate: line6Column17)
                    let mutatedSource = rewriter.visit(sourceWithLogicalOperators)
                    
                    expect(mutatedSource.description) == expectedSource.description
                }

            }
            
            describe("LogicalOperator.Visitor") {
                it("records the positions of code that contains a logical operator") {
                    
                    let visitor = ChangeLogicalConnectorOperator.Visitor()
                    visitor.visit(sourceWithLogicalOperators)
                    
                    guard visitor.positionsOfToken.count == 2 else {
                        fail("Expected 2 tokens to be discovered, got \(visitor.positionsOfToken.count) instead")
                        return
                    }
                    
                    expect(visitor.positionsOfToken[0].line).to(equal(2))
                    expect(visitor.positionsOfToken[1].line).to(equal(6))
                }
            }
        }
    }
}

