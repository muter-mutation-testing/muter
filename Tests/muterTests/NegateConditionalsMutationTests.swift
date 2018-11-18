import XCTest
import Foundation

final class NegateConditionalsMutationTests: XCTestCase {
    func test_negateConditionalsMutation() {
        let source = FileParser.load(path: "\(testDirectory)/fixtures/sample.swift")!
        let expectedSource = FileParser.load(path: "\(testDirectory)/fixtures/conditionalBoundary_mutation.swift")!
        
        let mutatedSource = NegateConditionalsMutation().mutate(source: source)
        XCTAssertEqual(mutatedSource.description, expectedSource.description)
        
    }
}
