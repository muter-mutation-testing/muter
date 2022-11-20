import Quick
import Nimble
import SwiftSyntax
@testable import muterCore

class ChangeLogicalConnectorOperatorSpec: QuickSpec {
    override func spec() {
        describe("") {
            let sourceWithLogicalOperators = sourceCode(fromFileAt: "\(self.fixturesDirectory)/MutationExamples/LogicalOperator/sampleWithLogicalOperators.swift")!
            
            let sampleWithCompilerDirectives = sourceCode(fromFileAt: "\(self.fixturesDirectory)/MutationExamples/LogicalOperator/sampleWithCompilerDirectives.swift")!
            
            describe("LogicalOperator.Rewriter") {
                
                it("converts a && operator to a || operator") {
                    let line2Column18 = MutationPosition(utf8Offset: 101, line: 6, column: 18)
                    let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/MutationExamples/LogicalOperator/changedANDOperator.swift")!

                    let rewriter = ChangeLogicalConnectorOperator.Rewriter(positionToMutate: line2Column18)
                    let mutatedSource = rewriter.visit(sourceWithLogicalOperators.code)

                    expect(mutatedSource.description) == expectedSource.code.description
                }

                it("converts a || operator to a && operator") {
                    let line6Column17 = MutationPosition(utf8Offset: 160, line: 10, column: 17)
                    let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/MutationExamples/LogicalOperator/changedOROperator.swift")!

                    let rewriter = ChangeLogicalConnectorOperator.Rewriter(positionToMutate: line6Column17)
                    let mutatedSource = rewriter.visit(sourceWithLogicalOperators.code)

                    expect(mutatedSource.description) == expectedSource.code.description
                }

            }
            
            describe("LogicalOperator.Visitor") {
                it("records the positions of code that contains a logical operator") {

                    let visitor = ChangeLogicalConnectorOperator.Visitor(sourceFileInfo: sourceWithLogicalOperators.asSourceFileInfo)
                    visitor.walk(sourceWithLogicalOperators.code)

                    guard visitor.positionsOfToken.count == 2 else {
                        fail("Expected 2 tokens to be discovered, got \(visitor.positionsOfToken.count) instead")
                        return
                    }

                    expect(visitor.positionsOfToken[safe: 0]?.line).to(equal(6))
                    expect(visitor.positionsOfToken[safe: 1]?.line).to(equal(10))
                }
                
                it("ignore lines with compiler directives") {
                    
                    let visitor = ChangeLogicalConnectorOperator.Visitor(sourceFileInfo: sampleWithCompilerDirectives.asSourceFileInfo)
                    visitor.walk(sampleWithCompilerDirectives.code)

                    guard visitor.positionsOfToken.count == 1 else {
                        fail("Expected 2 tokens to be discovered, got \(visitor.positionsOfToken.count) instead")
                        return
                    }

                    expect(visitor.positionsOfToken[safe: 0]?.line).to(equal(7))
                }
            }
        }
    }
}

