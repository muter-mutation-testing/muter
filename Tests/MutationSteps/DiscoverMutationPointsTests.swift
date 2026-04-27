@testable import muterCore
import SwiftSyntax
import XCTest

final class DiscoverMutationPointsTests: MuterTestCase {
    private let state = MutationTestState()
    private let sut = DiscoverMutationPoints()

    override func setUp() {
        super.setUp()

        state.mutationOperatorList = .allOperators
        prepareCode.sourceCodeToReturn = {
            muterCore.sourceCode(fromFileAt: $0).map {
                (
                    source: $0,
                    changes: .null
                )
            }
        }
    }

    func test_discoversMutations() async throws {
        state.sourceFileCandidates = [
            "\(fixturesDirectory)/sampleForDiscoveringMutations.swift",
            "\(fixturesDirectory)/sample With Spaces For Discovering Mutations.swift",
        ]

        let result = try await sut.run(with: state)
        let change = try XCTUnwrap(result.first)

        guard case let .mutationMappingsDiscovered(mappings) = change else {
            return XCTFail("Expected mappings, get \(change)")
        }

        XCTAssertEqual(mappings.count, 2)

        let sampleForDiscoveringMutations = mappings
            .first { $0.fileName.contains("sampleForDiscoveringMutations") }

        let ternaryOperatorSchemata = sampleForDiscoveringMutations?
            .mutationSchemata
            .include { $0.mutationOperatorId == .swapTernary }

        XCTAssertEqual(ternaryOperatorSchemata?.count, 1)

        let rorSchemata = sampleForDiscoveringMutations?
            .mutationSchemata
            .include { $0.mutationOperatorId == .ror }

        XCTAssertEqual(rorSchemata?.count, 2)

        let sampleWithSpacesForDiscoveringMutations = mappings
            .first { $0.fileName.contains("sample With Spaces For Discovering Mutations") }

        let removeSideEffectsSchemata = sampleWithSpacesForDiscoveringMutations?
            .mutationSchemata
            .include { $0.mutationOperatorId == .removeSideEffects }

        XCTAssertEqual(removeSideEffectsSchemata?.count, 2)
    }

    func test_shouldIgnoreUknownOperators() async throws {
        state.sourceFileCandidates = [
            "\(fixturesDirectory)/sourceWithoutMutableCode.swift",
        ]

        try await assertThrowsMuterError(
            await sut.run(with: state),
            .noMutationPointsDiscovered
        )
    }

    // MARK: - Large Codebase Tests (Parallel Processing)

    func test_discoversMultipleFilesInParallel() async throws {
        // Test that multiple files are processed correctly with parallel batching
        state.sourceFileCandidates = [
            "\(fixturesDirectory)/sampleForDiscoveringMutations.swift",
            "\(fixturesDirectory)/sample With Spaces For Discovering Mutations.swift",
        ]

        let result = try await sut.run(with: state)
        let change = try XCTUnwrap(result.first)

        guard case let .mutationMappingsDiscovered(mappings) = change else {
            return XCTFail("Expected mappings, got \(change)")
        }

        // Verify all files were processed
        XCTAssertEqual(mappings.count, 2)

        // Verify mutations were found in both files
        let fileNames = mappings.map { $0.fileName }
        XCTAssertTrue(fileNames.contains { $0.contains("sampleForDiscoveringMutations") })
        XCTAssertTrue(fileNames.contains { $0.contains("sample With Spaces") })
    }

    func test_returnsEmptySourceCodeDictionary() async throws {
        // The fix passes an empty dictionary to prevent memory exhaustion
        // ApplySchemata should re-parse files on demand
        state.sourceFileCandidates = [
            "\(fixturesDirectory)/sampleForDiscoveringMutations.swift",
        ]

        let result = try await sut.run(with: state)

        // Check that sourceCodeParsed change contains empty dictionary
        let sourceCodeChange = result.first { change in
            if case .sourceCodeParsed = change { return true }
            return false
        }

        guard case let .sourceCodeParsed(sourceCode) = sourceCodeChange else {
            return XCTFail("Expected sourceCodeParsed change")
        }

        XCTAssertTrue(sourceCode.isEmpty, "Source code dictionary should be empty to prevent memory exhaustion")
    }

    func test_handlesEmptyFileCandidates() async throws {
        state.sourceFileCandidates = []

        try await assertThrowsMuterError(
            await sut.run(with: state),
            .noMutationPointsDiscovered
        )
    }

    func test_handlesNonSwiftFiles() async throws {
        // Non-swift files should be filtered out
        state.sourceFileCandidates = [
            "\(fixturesDirectory)/someFile.txt",
            "\(fixturesDirectory)/sampleForDiscoveringMutations.swift",
        ]

        let result = try await sut.run(with: state)
        let change = try XCTUnwrap(result.first)

        guard case let .mutationMappingsDiscovered(mappings) = change else {
            return XCTFail("Expected mappings, got \(change)")
        }

        // Only Swift files should be processed
        XCTAssertEqual(mappings.count, 1)
        XCTAssertTrue(mappings[0].fileName.hasSuffix(".swift"))
    }
}
