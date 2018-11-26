import XCTest
import Foundation

final class NegateConditionalsMutationTests: XCTestCase {
    func test_negateConditionalsMutation() {
        let source = FileParser.load(path: "\(fixturesDirectory)/sample.swift")!
        let expectedSource = FileParser.load(path: "\(fixturesDirectory)/conditionalBoundary_mutation.swift")!
        
        let mutatedSource = NegateConditionalsMutation().mutate(source: source)
        XCTAssertEqual(mutatedSource.description, expectedSource.description)
        
    }
    
    func test_determinesIfItCanMutateSourceCode() {
        let mutation = NegateConditionalsMutation()
        let sourceWithConditionalLogic = FileParser.load(path: "\(fixturesDirectory)/sample.swift")!
        let sourceWithoutConditionalLogic = FileParser.load(path: "\(fixturesDirectory)/sourceWithoutConditionalLogic.swift")!
        
        XCTAssert(mutation.canMutate(source: sourceWithConditionalLogic))
        XCTAssertFalse(mutation.canMutate(source: sourceWithoutConditionalLogic))

    }
}
