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

    // Regression for #302: discovery handed ApplySchemata an empty
    // `sourceCodeParsed` dictionary, so the rewriter never matched a node
    // and every schemata was silently dropped — the mutated copy ran the
    // original code, collapsing the mutation score. Every file that produced
    // mutations must carry its parsed source so ApplySchemata can rewrite the
    // very tree the mapping keys belong to.
    func test_cachesParsedSourceForMutatedFiles() async throws {
        state.sourceFileCandidates = [
            "\(fixturesDirectory)/sampleForDiscoveringMutations.swift",
            "\(fixturesDirectory)/sample With Spaces For Discovering Mutations.swift",
        ]

        let result = try await sut.run(with: state)

        let sourceCodeByFilePath = result
            .compactMap { change -> [FilePath: SourceFileSyntax]? in
                guard case let .sourceCodeParsed(byPath) = change else {
                    return nil
                }
                return byPath
            }
            .first

        let byPath = try XCTUnwrap(
            sourceCodeByFilePath,
            "Discovery must emit a .sourceCodeParsed change"
        )

        XCTAssertFalse(
            byPath.isEmpty,
            "No parsed source cached — ApplySchemata cannot apply any schemata"
        )
        XCTAssertTrue(
            byPath.keys.contains { $0.contains("sampleForDiscoveringMutations") },
            "Mutated file's parsed source missing from cache: \(Array(byPath.keys))"
        )
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

    // Memory stays bounded by caching *only* the files that produced
    // mutations — not by dropping every file's source (which broke
    // ApplySchemata entirely, see test_cachesParsedSourceForMutatedFiles).
    func test_doesNotCacheSourceForFilesWithoutMutations() async throws {
        state.sourceFileCandidates = [
            "\(fixturesDirectory)/sampleForDiscoveringMutations.swift",
            "\(fixturesDirectory)/sourceWithoutMutableCode.swift",
        ]

        let result = try await sut.run(with: state)

        let sourceCodeByFilePath = result
            .compactMap { change -> [FilePath: SourceFileSyntax]? in
                guard case let .sourceCodeParsed(byPath) = change else {
                    return nil
                }
                return byPath
            }
            .first

        let byPath = try XCTUnwrap(
            sourceCodeByFilePath,
            "Discovery must emit a .sourceCodeParsed change"
        )

        XCTAssertTrue(
            byPath.keys.contains { $0.contains("sampleForDiscoveringMutations") },
            "Mutated file's parsed source must be cached: \(Array(byPath.keys))"
        )
        XCTAssertFalse(
            byPath.keys.contains { $0.contains("sourceWithoutMutableCode") },
            "File without mutations must not be cached (keeps memory bounded)"
        )
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
