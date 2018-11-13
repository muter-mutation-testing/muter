import XCTest
import class Foundation.Bundle

final class NegateConditionalsMutationTests: XCTestCase {
    func test_negateConditionalsMutation() {
        let source = FileParser.load(path: "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/sample.swift")
        let expectedSource = FileParser.load(path: "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/conditionalBoundary_mutation.swift")
        
        let mutatedSource = NegateConditionalsMutation().mutate(source: source)
        XCTAssertEqual(mutatedSource.description, expectedSource.description)
        
    }
    
    static var allTests = [
        ("\(test_negateConditionalsMutation)", test_negateConditionalsMutation)
    ]
}
