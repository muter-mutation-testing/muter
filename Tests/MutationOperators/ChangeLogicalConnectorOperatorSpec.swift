import Quick
import Nimble
import SwiftSyntax
@testable import muterCore

extension Id where Value == Int {
    private static var _nextId: Int = 0
    
    static var nextId: Id {
        let next = Id(value: _nextId)
        _nextId += 1
        return next
    }
}

//{
//let instance: Observer = Observer()
//XCTestObservationCenter.shared.addTestObserver(instance)
//}
class CodeCoverageSpec: QuickSpec {
    
    override func spec() {
        describe("CodeCoverageInstrumenter") {
            it("records the strings that get passed to it") {
                let instrumenter = CodeCoverageInstrumenter() { _ in /* no op */ }

                expect(instrumenter.functionCallCounts[#function]).to(beNil())

                instrumenter.recordFunctionCall(forFunctionNamed: #function)
                
                expect(instrumenter.functionCallCounts[#function]) == 1
            }
            
            it("uses its persistence handler") {
                var recordedFunctionInvocations: [String: Int]?
                let persistenceSpy =  {
                    recordedFunctionInvocations = $0
                }
                
                let instrumenter = CodeCoverageInstrumenter(persistenceHandler: persistenceSpy)
                
                instrumenter.recordFunctionCall(forFunctionNamed: #function)
                instrumenter.recordFunctionCall(forFunctionNamed: #function)

                instrumenter.persistFunctionCalls()
                
                expect(recordedFunctionInvocations?[#function]) == 2
            }
        }
        
        describe("InstrumentationVisitor") {
            let source = sourceCode(fromFileAt: "\(self.fixturesDirectory)/uninstrumentedSample.swift")!
            let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/instrumentedSample.swift")!

            
            it("inserts instrumentation code at the first line of every function") {
                
                let visitor = InstrumentationVisitor { functionName in
                    return SyntaxFactory
                        .makeBlankCodeBlockItem()
                        .withItem(SyntaxFactory.makeTokenList([
                            SyntaxFactory
                                .makeIdentifier("\(functionName)")
                                .withLeadingTrivia([.newlines(1)])
                            ]))
                }

                let instrumentedCode = visitor.visit(source)
                
                expect(instrumentedCode.description) == expectedSource.description

            }
            
            it("") {
                let source = sourceCode(fromFileAt: "\(self.fixturesDirectory)/sampleForParsingFunctionNames.swift")!

                var instrumentedFunctions: [String] = []
                let visitor = InstrumentationVisitor {
                    instrumentedFunctions.append($0)
                    return SyntaxFactory.makeBlankCodeBlockItem()
                }
                
                _ = visitor.visit(source)

                expect(visitor.instrumentedFunctions) == instrumentedFunctions
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

            it("returns instrumentation for measuring code coverage") {
                let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/instrumentationExample.swift")!
                let source = InstrumentationVisitor.default("foo")
                expect(source.description.trimmed) == expectedSource.description.trimmed

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

