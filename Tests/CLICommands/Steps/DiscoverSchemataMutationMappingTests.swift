import XCTest
import SwiftSyntax

@testable import muterCore

final class DiscoverSchemataMutationMappingTests: XCTestCase {
    private let state = RunCommandState()
    private let sut = DiscoverSchemataMutationMapping(
        prepareSourceCode: { path in
            muterCore.sourceCode(fromFileAt: path).map {
                (
                    source: $0,
                    changes: .null
                )
            }
        }
    )
    
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
        
        XCTAssertEqual(mappings.count, 2)

        let sampleForDiscoveringMutations = mappings
            .first { $0.fileName.contains("sampleForDiscoveringMutations") }
        
        let ternaryOperatorSchematas = sampleForDiscoveringMutations?
            .schematas
            .include { $0.mutationOperatorId == .ternaryOperator }
    
        XCTAssertEqual(ternaryOperatorSchematas?.count, 1)
        
        let rorSchematas = sampleForDiscoveringMutations?
            .schematas
            .include { $0.mutationOperatorId == .ror }

        XCTAssertEqual(rorSchematas?.count, 2)

        let sampleWithSpacesForDiscoveringMutations = mappings
            .first { $0.fileName.contains("sample With Spaces For Discovering Mutations") }
        
        let removeSideEffectsSchematas = sampleWithSpacesForDiscoveringMutations?
            .schematas
            .include { $0.mutationOperatorId == .removeSideEffects }

        XCTAssertEqual(removeSideEffectsSchematas?.count, 2)
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
        
        XCTAssertEqual(mappings.first?.schematas.count, 1)
    }
    
    func test_shouldIgnoreUknownOperators() {
        state.sourceFileCandidates = [
            "\(fixturesDirectory)/sourceWithoutMutableCode.swift",
        ]
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(result, .failure(.noMutationPointsDiscovered))
    }
}

final class Integration: XCTestCase {
    private lazy var state: RunCommandState = {
        $0.tempDirectoryURL = URL(fileURLWithPath: fixturesDirectory)
        $0.sourceFileCandidates = [
            "\(fixturesDirectory)/sampleWithNestedMutation.swift"
        ]
        
        return $0
    }(RunCommandState())
    
    private let sut = DiscoverSchemataMutationMapping()
    
    func test_() throws {
        let result = try XCTUnwrap(sut.run(with: state).get())
        

        
    }

    func test__() throws {
        var sampleCode = sourceCode(
            fromFileAt: "\(fixturesDirectory)/sampleWithNestedMutation.swift"
        )!

        let visitor = ROROperator.SchemataVisitor(
            sourceFileInfo: sampleCode.asSourceFileInfo
        )
        
        visitor.walk(sampleCode.code)
        
        let rewriter = MutationSchemataRewriter(visitor.schemataMappings)
            .visit(sampleCode.code)
        
        print(rewriter.description)
    }
}
