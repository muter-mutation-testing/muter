import Quick
import Nimble
import SwiftSyntax
@testable import muterCore

class InstrumentationVisitor: SyntaxRewriter {
    private let instrumentation: CodeBlockItemSyntax
    
    init(instrumentation: CodeBlockItemSyntax) {
        self.instrumentation = instrumentation
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let existingBody = node.body!
        return node.withBody(existingBody.withStatements(
            existingBody
                .statements
                .inserting(instrumentation, at: 0)
        ))
    }
    
}




import XCTest

class Observer: NSObject, XCTestObservation {
    func testBundleDidFinish(_ testBundle: Bundle) {
        print("ea")
        CodeCoverageInstrumenter.shared.recordFunctionInvocation(with: Id<Int>(value: 5))
    }
    
}



class CodeCoverageSpec: QuickSpec {
    
    func something(_ value: String) -> [Result<(), Never>] {
        let function = #function

        return []
    }
    
    func something(_ value: Int) -> [Result<(), Never>] {
        let function = #function
        
        
        return []
    }
    
    override func spec() {
        describe("CodeCoverageInstrumenter") {
            XCTestObservationCenter.shared.addTestObserver(Observer())
            it("records the strings that get passed to it") {
                
//                self.something("")
                self.something(0)
            }
            
        }
        describe("InstrumentationVisitor") {
            it("inserts instrumentation code at the first line of every function") {
                let source = sourceCode(fromFileAt: "\(self.fixturesDirectory)/sampleForDiscoveringMutations.swift")!
                let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/instrumentedSample.swift")!
                let instrumentation = SyntaxFactory.makeBlankCodeBlockItem().withItem(SyntaxFactory.makeTokenList([
                    SyntaxFactory
                        .makeIdentifier("instrumented")
                        .withLeadingTrivia([.newlines(1), .spaces(8), .docLineComment("//"), .spaces(1)])
                ]))
                
                let instrumentedCode = InstrumentationVisitor(instrumentation: instrumentation).visit(source)
                
                expect(instrumentedCode.description) == expectedSource.description
            }
        }
    }
}


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

