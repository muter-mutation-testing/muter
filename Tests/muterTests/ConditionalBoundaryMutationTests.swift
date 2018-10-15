import XCTest
import class Foundation.Bundle

final class ConditionalBoundaryMutationTests: XCTestCase {
    func test_conditionalBoundaryMutation() {
        let source = try! FileParser().load(path: "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/sample.swift")
        let expectedSource = try! FileParser().load(path: "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/conditionalBoundary_mutation.swift")
        
        let mutatedSource = ConditionalBoundaryMutation().mutate(source: source)
        XCTAssertEqual(mutatedSource.description, expectedSource.description)
        
    }
    
    static var allTests = [
        ("\(test_conditionalBoundaryMutation)", test_conditionalBoundaryMutation)
    ]
}
