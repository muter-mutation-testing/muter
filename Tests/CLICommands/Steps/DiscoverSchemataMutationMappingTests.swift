import XCTest
import SwiftSyntax

@testable import muterCore

final class DiscoverSchemataMutationMappingTests: XCTestCase {
    private let state = RunCommandState()
    private let sut = DiscoverSchemataMutationMapping()
    
    func test_discoversMutations() throws {
        state.sourceFileCandidates = [
            "\(fixturesDirectory)/sampleForDiscoveringMutations.swift",
            "\(fixturesDirectory)/sample With Spaces For Discovering Mutations.swift",
        ]

        let result = try XCTUnwrap(sut.run(with: state).get())
        let change = try XCTUnwrap(result.first)
        
        guard case .mutationMappingsDiscovered(let mappings) = change else {
            return XCTFail("Expected mappings, get \(change)")
        }
        
        XCTAssertEqual(mappings.count, 3)

        let rorSchematas = try XCTUnwrap(mappings.first(by: .ror))
        XCTAssertEqual(rorSchematas.schematas.count, 2)
        
        let removeSideEffectsSchematas = try XCTUnwrap(mappings.first(by: .removeSideEffects))
        XCTAssertEqual(removeSideEffectsSchematas.schematas.count, 2)
        
        let ternaryOperatorSchematas = try XCTUnwrap(mappings.first(by: .ternaryOperator))
        XCTAssertEqual(ternaryOperatorSchematas.schematas.count, 1)
    }
    
    func test_shouldIgnoreSkippedLines() throws {
        let samplePath = "\(fixturesDirectory)/sample with mutations marked for skipping.swift"
        state.sourceFileCandidates = [samplePath]
        
        let result = try XCTUnwrap(sut.run(with: state).get())
        let change = try XCTUnwrap(result.first)
        
        guard case .mutationMappingsDiscovered(let mappings) = change else {
            return XCTFail("Expected mappings, get \(change)")
        }
        
        XCTAssertEqual(mappings.count, 1)

        let schematas = try XCTUnwrap(mappings.first(by: .removeSideEffects))
        
        XCTAssertEqual(schematas.count, 1)
    }
    
    func test_shouldIgnoreUknownOperators() {
        state.sourceFileCandidates = [
            "\(fixturesDirectory)/sourceWithoutMutableCode.swift",
        ]
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(result, .failure(.noMutationPointsDiscovered))
    }
}

