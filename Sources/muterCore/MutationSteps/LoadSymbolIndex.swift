import Foundation

/// Reads the index store that the coverage build wrote, for the files that Muter can mutate.
/// The index tells Muter the types in the unmutated code, such as the function that an operator
/// calls.
///
/// Nothing fails when the index is missing: Muter then mutates without type information.
struct LoadSymbolIndex: MutationStep {
    private let loadLibrary: () -> IndexStoreLibrary?

    init(loadLibrary: @escaping () -> IndexStoreLibrary? = Self.toolchainLibrary) {
        self.loadLibrary = loadLibrary
    }

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        guard let path = state.projectCoverage.indexStorePath else {
            CoverageDiagnostics.debug("index store: the build system has none")
            return []
        }

        guard FileManager.default.fileExists(atPath: path) else {
            CoverageDiagnostics.debug("index store: \(path) does not exist")
            return []
        }

        guard let library = loadLibrary() else {
            CoverageDiagnostics.debug("index store: the Swift toolchain has no libIndexStore")
            return []
        }

        do {
            let store = try IndexStore(path: path, library: library)
            let index = SymbolIndex(occurrences: store.occurrences(inFiles: state.sourceFileCandidates))
            CoverageDiagnostics.debug("index store: \(path), \(index.count) occurrences")
            return [.symbolIndexLoaded(index)]
        } catch {
            CoverageDiagnostics.debug("index store: \(error)")
            return []
        }
    }

    static func toolchainLibrary() -> IndexStoreLibrary? {
        SwiftToolchain.current().flatMap(IndexStoreLibrary.init(toolchain:))
    }
}
