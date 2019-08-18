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
    
    #if DEBUG
    static func resetIds() { // This is a testing hook
        _nextId = 0
    }
    #endif
    
    static var nextId: Id {
        let next = Id(value: _nextId)
        _nextId += 1
        return next
    }
}

class InstrumentationVisitor: SyntaxRewriter {
    private let instrumentation: CodeBlockItemSyntax
    private(set) var functionIds: [String: Id<Int>] = [:]
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
        updateTypeNameStack(with: node.identifier.text)
        return super.visit(node)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        updateTypeNameStack(with: node.identifier.text)
        return super.visit(node)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        updateTypeNameStack(with: node.identifier.text)
        return super.visit(node)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        updateTypeNameStack(with: node.extendedType.description)
        return super.visit(node)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard let existingBody = node.body else {
            return super.visit(node)
        }
        
        functionIds[fullyQualifiedFunctionName(for: node)] = .nextId
        
        return node.withBody(existingBody.withStatements(
            existingBody
                .statements
                .inserting(instrumentation, at: 0)
        ))
    }
    
    private func fullyQualifiedFunctionName(for node: FunctionDeclSyntax) -> String {
        let typeName = typeNameStack.last != nil ? "\(typeNameStack.last!)." : ""
        return (typeName + node.identifier.description + node.signature.description).trimmed
    }
    
    private func updateTypeNameStack(with identifier: String) {
        if typeNameStack.isEmpty {
            typeNameStack.append(identifier.trimmed)
        } else {
            var typeName = typeNameStack.last!
            typeName += ".\(identifier.trimmed)"
            typeNameStack[typeNameStack.endIndex - 1] = typeName
        }
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
                
                //                expect(instrumentedCode.description) == expectedSource.description
            }
            
            it("inserts instrumentation code at the first line of every function") {
                Id<Int>.resetIds() // This ensures that the id values start @ 0 for this test
                
                let visitor = InstrumentationVisitor(instrumentation: instrumentation)
                _ = visitor.visit(source)
                
                
                let actualIds =
                    visitor.functionIds.map { ($0.key, $0.value) }.sorted { (lhs, rhs) in
                    lhs.1.value < rhs.1.value
                }
                
                let expectedIdCount = 17
                guard actualIds.count == expectedIdCount else {
                    fail("expected there to be \(expectedIdCount) ids but got \(actualIds.count)")
                    return
                    
                }
                expect(actualIds[0].0) == "Example2.areEqualAsString(_ a: Int) -> String"
                expect(actualIds[0].1) == Id(value: 0)
                
                expect(actualIds[1].0) == "Example2.areEqualAsString(_ a: Float) -> String"
                expect(actualIds[1].1) == Id(value: 1)
                
                expect(actualIds[2].0) == "areEqualAsString(_ a: Float) -> String"
                expect(actualIds[2].1) == Id(value: 2)
                
                expect(actualIds[3].0) == "Example.foo(_ a: [Int])"
                expect(actualIds[3].1) == Id(value: 3)
                
                expect(actualIds[4].0) == "notTheSameThing()"
                expect(actualIds[4].1) == Id(value: 4)
                
                expect(actualIds[5].0) == "ExampleEnum.foo(dictionary: [String: Result<(), Never>]) -> ExampleEnum"
                expect(actualIds[5].1) == Id(value: 5)
                
                expect(actualIds[6].0) == "anotherNotTheSameThing()"
                expect(actualIds[6].1) == Id(value: 6)
                
                expect(actualIds[7].0) == "ExampleEnum.bar()"
                expect(actualIds[7].1) == Id(value: 7)
                
                expect(actualIds[8].0) == "andAnotherNotTheSameThing()"
                expect(actualIds[8].1) == Id(value: 8)
                
                expect(actualIds[9].0) == "SomeProtocol.kangaroo()"
                expect(actualIds[9].1) == Id(value: 9)
                
                expect(actualIds[10].0) == "thisShouldntBeASurpriseByNow()"
                expect(actualIds[10].1) == Id(value: 10)
                
                expect(actualIds[11].0) == "Baz.Info.foo()"
                expect(actualIds[11].1) == Id(value: 11)
                
                expect(actualIds[12].0) == "Bar.Info.foo()"
                expect(actualIds[12].1) == Id(value: 12)
                
                expect(actualIds[13].0) == "Info.foo()"
                expect(actualIds[13].1) == Id(value: 13)
                
                expect(actualIds[14].0) == "Info.CustomError.haltAndCatchFire ()" // note the space
                expect(actualIds[14].1) == Id(value: 14)
                
                expect(actualIds[15].0) == "Info.CustomError.AnotherLayer.ofHell(dictionary: [String: Result<(), Never>]) -> ExampleEnum"
                expect(actualIds[15].1) == Id(value: 15)
                
                expect(actualIds[16].0) == "ItsAlmostLikeItNeverEnds.DoesIt.endIt() -> Please"
                expect(actualIds[16].1) == Id(value: 16)
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

