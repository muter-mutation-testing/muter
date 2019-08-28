import Quick
import Nimble
import SwiftSyntax
@testable import muterCore

class InstrumentationVisitorSpec: QuickSpec {
    override func spec() {
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
            
            it("generates a fully qualified function name for every function it instruments") {
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
                let source = InstrumentationVisitor.defaultInstrumentation("foo")
                expect(source.description.trimmed) == expectedSource.description.trimmed
                
            }
        }
    }
}
