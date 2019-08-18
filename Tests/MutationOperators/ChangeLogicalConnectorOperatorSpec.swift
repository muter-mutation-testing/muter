import Quick
import Nimble
import SwiftSyntax
@testable import muterCore

//import XCTest
//
////            XCTestObservationCenter.shared.addTestObserver(Observer())
//class Observer: NSObject, XCTestObservation {
//    func testBundleDidFinish(_ testBundle: Bundle) {
//        //        print("ea")
//        //        CodeCoverageInstrumenter.shared.recordFunctionInvocation(with: Id<Int>(value: 5))
//    }
//
//}

extension Id where Value == Int {
    private static var _nextId: Int = 0
    
    static var nextId: Id {
        let next = Id(value: _nextId)
        _nextId += 1
        return next
    }
}

class InstrumentationVisitor: SyntaxRewriter {
    private let instrumentation: CodeBlockItemSyntax
    private(set) var instrumentedFunctions: [String] = []
    private var typeNameStack: [String] = []
    
    init(instrumentation: CodeBlockItemSyntax) {
        self.instrumentation = instrumentation
    }
    
    override func visitPost(_ node: Syntax) {
        switch node {
        case is StructDeclSyntax,
             is EnumDeclSyntax,
             is ClassDeclSyntax,
             is ExtensionDeclSyntax:
            _ = typeNameStack.popLast()
        default:
            break
        }
    }
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        typeNameStack.append(node.identifier.text.trimmed)
        return super.visit(node)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        typeNameStack.append(node.identifier.text.trimmed)
        return super.visit(node)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        typeNameStack.append(node.identifier.text.trimmed)
        return super.visit(node)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        typeNameStack.append(node.extendedType.description.trimmed)
        return super.visit(node)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard let existingBody = node.body else {
            return super.visit(node)
        }
        
        instrumentedFunctions.append(fullyQualifiedFunctionName(for: node))
        
        return node.withBody(existingBody.withStatements(
            existingBody
                .statements
                .inserting(instrumentation, at: 0)
        ))
    }
    
    private func fullyQualifiedFunctionName(for node: FunctionDeclSyntax) -> String {
        let typeName = typeNameStack.accumulate(into: "") {
            $0.isEmpty ?
                $1 + "." :
                $0 + "\($1)."
        }
        return (typeName +
            node.identifier.description +
            node.signature.description).trimmed
    }
}

class CodeCoverageSpec: QuickSpec {
    
    override func spec() {
        describe("CodeCoverageInstrumenter") {
            it("records the strings that get passed to it") {
                
            }
            
        }
        describe("InstrumentationVisitor") {
            let source = sourceCode(fromFileAt: "\(self.fixturesDirectory)/sampleForDiscoveringMutations.swift")!
            let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/instrumentedSample.swift")!
            let instrumentation = SyntaxFactory.makeBlankCodeBlockItem().withItem(SyntaxFactory.makeTokenList([
                SyntaxFactory
                    .makeIdentifier("instrumented")
                    .withLeadingTrivia([.newlines(1), .spaces(8), .docLineComment("//"), .spaces(1)])
                ]))
            
            it("inserts instrumentation code at the first line of every function") {
                
                let instrumentedCode = InstrumentationVisitor(instrumentation: instrumentation).visit(source)
                
                                expect(instrumentedCode.description) == expectedSource.description
            }
            
            it("inserts instrumentation code at the first line of every function") {
                let visitor = InstrumentationVisitor(instrumentation: instrumentation)
                _ = visitor.visit(source)
                expect(visitor.instrumentedFunctions) == [
                    "Example2.areEqualAsString(_ a: Int) -> String",
                    "Example2.areEqualAsString(_ a: Float) -> String",
                    "areEqualAsString(_ a: Float) -> String",
                    "Example.foo(_ a: [Int])",
                    "notTheSameThing()",
                    "ExampleEnum.foo(dictionary: [String: Result<(), Never>]) -> ExampleEnum",
                    "anotherNotTheSameThing()",
                    "ExampleEnum.bar()",
                    "andAnotherNotTheSameThing()",
                    "SomeProtocol.kangaroo()",
                    "thisShouldntBeASurpriseByNow()",
                    "Baz.Info.foo()",
                    "Bar.Info.foo()",
                    "Info.foo()",
                    "Info.CustomError.haltAndCatchFire ()", // note the space
                    "Info.CustomError.AnotherLayer.ofHell(dictionary: [String: Result<(), Never>]) -> ExampleEnum",
                    "ItsAlmostLikeItNeverEnds.DoesIt.endIt() -> Please"
                ]
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

