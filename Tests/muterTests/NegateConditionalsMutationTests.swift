import XCTest
import Foundation
import SwiftSyntax

class SourceCodeMutationDelegateSpy: Spy, SourceCodeMutationDelegate  {
    private(set) var methodCalls: [String] = []
    private(set) var mutatedFileContents: [String] = []
    private(set) var mutatedFilePaths: [String] = []
    
    func writeFile(filePath: String, contents: String) throws {
        methodCalls.append(#function)
        mutatedFilePaths.append(filePath)
        mutatedFileContents.append(contents)
    }
}

final class NegateConditionalsMutationTests: XCTestCase {
    var sourceWithConditionalLogic: SourceFileSyntax!
    var sourceWithoutConditionalLogic: SourceFileSyntax!
    
    override func setUp() {
        sourceWithConditionalLogic = FileParser.load(path: "\(fixturesDirectory)/sample.swift")!
        sourceWithoutConditionalLogic = FileParser.load(path: "\(fixturesDirectory)/sourceWithoutConditionalLogic.swift")!
    }
    
    func test_negateConditionalsMutation() {
        let expectedSource = FileParser.load(path: "\(fixturesDirectory)/conditionalBoundary_mutation.swift")!

        let delegateSpy = SourceCodeMutationDelegateSpy()
        let positionToMutate = AbsolutePosition(line: 3, column: 19, utf8Offset: 76)
        let rewriter = NegateConditionalsMutation.Rewriter(positionToMutate: positionToMutate)
        
        let mutation =  NegateConditionalsMutation(filePath: "path",
                                                   sourceCode: sourceWithConditionalLogic,
                                                   rewriter: rewriter,
                                                   delegate: delegateSpy)
        mutation.mutate()
        
        XCTAssertEqual(delegateSpy.methodCalls, ["writeFile(filePath:contents:)"])
        XCTAssertEqual(delegateSpy.mutatedFileContents.first, expectedSource.description)
        XCTAssertEqual(delegateSpy.mutatedFilePaths.first, "path")

    }

    func test_visitorNotesThePositionsWhereItDiscoveredItsToken() {
        var visitor = NegateConditionalsMutation.Visitor()
        
        visitor.visit(sourceWithConditionalLogic)
        
        XCTAssertEqual(visitor.positionsOfToken.count, 3)
        XCTAssertEqual(visitor.positionsOfToken.first?.line, 3)
        XCTAssertEqual(visitor.positionsOfToken.last?.line, 7)
        
        visitor = NegateConditionalsMutation.Visitor()
        visitor.visit(sourceWithoutConditionalLogic)
        XCTAssertEqual(visitor.positionsOfToken.count, 0)
    }
    
    func test_rewriterI() {
        
        let positionToMutate = AbsolutePosition(line: 3, column: 19, utf8Offset: 76)
        let rewriter = NegateConditionalsMutation.Rewriter(positionToMutate: positionToMutate)
        let mutatedSource = rewriter.visit(sourceWithConditionalLogic)
                let expectedSource = FileParser.load(path: "\(fixturesDirectory)/conditionalBoundary_mutation.swift")!
        XCTAssertEqual(mutatedSource.description, expectedSource.description)
    }
    
}
