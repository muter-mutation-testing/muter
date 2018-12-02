import XCTest
import Foundation
import SwiftSyntax

final class NegateConditionalsMutationTests: XCTestCase {
    var mutation: SourceCodeMutation!
    var sourceWithConditionalLogic: SourceFileSyntax!
    var sourceWithoutConditionalLogic: SourceFileSyntax!
    
    override func setUp() {
        mutation = NegateConditionalsMutation()
        sourceWithConditionalLogic = FileParser.load(path: "\(fixturesDirectory)/sample.swift")!
        sourceWithoutConditionalLogic = FileParser.load(path: "\(fixturesDirectory)/sourceWithoutConditionalLogic.swift")!
    }
    
    func test_negateConditionalsMutation() {
        let source = FileParser.load(path: "\(fixturesDirectory)/sample.swift")!
        let expectedSource = FileParser.load(path: "\(fixturesDirectory)/conditionalBoundary_mutation.swift")!
        
        let mutatedSource = mutation.mutate(source: source)
        XCTAssertEqual(mutatedSource.description, expectedSource.description)
    }
    
    func test_determinesIfItCanMutateSourceCode() {
        XCTAssert(mutation.canMutate(source: sourceWithConditionalLogic))
        XCTAssertFalse(mutation.canMutate(source: sourceWithoutConditionalLogic))
    }
    
    func test_reportsTheNumberOfIntroducedMutations() {
        _ = mutation.mutate(source: sourceWithConditionalLogic)
        XCTAssertEqual(mutation.numberOfMutations, 3)
        
        _ = mutation.mutate(source: sourceWithoutConditionalLogic)
        XCTAssertEqual(mutation.numberOfMutations, 0)
    }
}
