import Foundation

/// Reads the index store that the coverage build wrote, for the files that Muter can mutate.
/// The index tells Muter the types in the unmutated code, such as the function that an operator
/// calls.
///
/// Nothing fails when the index is missing: Muter then mutates without type information.
struct LoadSymbolIndex: MutationStep {
    private let loadLibrary: () -> IndexStoreLibrary?
    private let demangle: ([String]) -> [String: String]

    init(
        loadLibrary: @escaping () -> IndexStoreLibrary? = Self.toolchainLibrary,
        demangle: @escaping ([String]) -> [String: String] = Self.toolchainDemangle
    ) {
        self.loadLibrary = loadLibrary
        self.demangle = demangle
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
            let occurrences = store.occurrences(inFiles: state.sourceFileCandidates)
            // Only the operators that a type-aware operator checks need a signature. One
            // `swift-demangle` run reads them all.
            let signatures = demangle(
                SymbolIndex.referencedUSRs(in: occurrences, named: ArithmeticOperatorReplacement.symbolNames)
            )
            let index = SymbolIndex(occurrences: occurrences, signatures: signatures)
            CoverageDiagnostics.debug("index store: \(path), \(index.count) occurrences, \(signatures.count) signatures")
            return [.symbolIndexLoaded(index)]
        } catch {
            CoverageDiagnostics.debug("index store: \(error)")
            return []
        }
    }

    static func toolchainLibrary() -> IndexStoreLibrary? {
        SwiftToolchain.current().flatMap(IndexStoreLibrary.init(toolchain:))
    }

    static func toolchainDemangle(_ usrs: [String]) -> [String: String] {
        guard !usrs.isEmpty, let toolchain = SwiftToolchain.current() else {
            return [:]
        }

        return SwiftDemangler(toolchain: toolchain).demangle(usrs)
    }
}
