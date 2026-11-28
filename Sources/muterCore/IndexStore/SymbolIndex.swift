import Foundation

/// The occurrences of an index store, ready to look up by source position. Muter uses it to learn
/// the types around a mutation point: which function an operator calls, what a function returns,
/// and which protocols a type conforms to.
struct SymbolIndex: Equatable {
    private struct Position: Hashable {
        let filePath: String
        let line: Int
        let column: Int
    }

    private let occurrencesByPosition: [Position: [IndexOccurrence]]
    /// The protocols that each type conforms to in the indexed code, by USR. A conformance in an
    /// extension counts for the extended type.
    private let protocolsByType: [String: Set<String>]
    /// The USRs that the indexed code defines. A system symbol, such as `Int.max`, is not among them.
    private let definedUSRs: Set<String>
    /// The signatures with types of some symbols, by USR, such as
    /// `static Swift.Int.+ infix(Swift.Int, Swift.Int) -> Swift.Int`.
    private let signaturesByUSR: [String: String]

    /// The number of occurrences in the index.
    let count: Int

    init(occurrences: [IndexOccurrence], signatures: [String: String] = [:]) {
        count = occurrences.count
        signaturesByUSR = signatures
        definedUSRs = Set(occurrences.filter { $0.roles.contains(.definition) }.map(\.symbol.usr))
        // Few files, many occurrences: each path resolves once.
        var normalizedPaths: [String: String] = [:]
        occurrencesByPosition = Dictionary(grouping: occurrences) { occurrence in
            let path = normalizedPaths[occurrence.filePath] ?? {
                let normalized = Self.normalized(occurrence.filePath)
                normalizedPaths[occurrence.filePath] = normalized
                return normalized
            }()
            return Position(filePath: path, line: occurrence.line, column: occurrence.column)
        }

        // `extension Point: Comparable` records Comparable as a base of the extension, and Point
        // as extended by the extension.
        var extendedTypes: [String: String] = [:]
        for occurrence in occurrences where occurrence.symbol.kind.isType {
            for relation in occurrence.relations where relation.roles.contains(.extendedBy) {
                extendedTypes[relation.symbol.usr] = occurrence.symbol.usr
            }
        }

        var protocolsByType: [String: Set<String>] = [:]
        for occurrence in occurrences where occurrence.symbol.kind == .protocol {
            for relation in occurrence.relations where relation.roles.contains(.baseOf) {
                let type = extendedTypes[relation.symbol.usr] ?? relation.symbol.usr
                protocolsByType[type, default: []].insert(occurrence.symbol.usr)
            }
        }
        self.protocolsByType = protocolsByType
    }

    /// The occurrences whose name starts at this line and UTF-8 column, both from 1.
    func occurrences(inFile filePath: String, line: Int, column: Int) -> [IndexOccurrence] {
        occurrencesByPosition[Position(filePath: Self.normalized(filePath), line: line, column: column)] ?? []
    }

    /// The symbol that the code at this position uses, such as the function that an operator or a
    /// call resolves to. Implicit occurrences, which the compiler adds for code that is not written,
    /// such as a synthesized initializer at a type's name, are left out.
    func referencedSymbol(inFile filePath: String, line: Int, column: Int) -> IndexSymbol? {
        occurrences(inFile: filePath, line: line, column: column)
            .first { $0.roles.contains(.reference) && !$0.roles.contains(.implicit) }?
            .symbol
    }

    /// The symbol that the code at this position defines, such as a function whose name starts here.
    func definedSymbol(inFile filePath: String, line: Int, column: Int) -> IndexSymbol? {
        occurrences(inFile: filePath, line: line, column: column)
            .first { $0.roles.contains(.definition) && !$0.roles.contains(.implicit) }?
            .symbol
    }

    /// Whether the indexed code defines the symbol, as opposed to a module that it imports.
    func defines(_ symbol: IndexSymbol) -> Bool {
        definedUSRs.contains(symbol.usr)
    }

    /// The signature with types of the symbol, when Muter demangled it while it loaded the index.
    func signature(of symbol: IndexSymbol) -> String? {
        signaturesByUSR[symbol.usr]
    }

    /// The USRs of the symbols that the indexed code references with one of these names, such as
    /// `+(_:_:)`.
    static func referencedUSRs(in occurrences: [IndexOccurrence], named names: Set<String>) -> [String] {
        Array(Set(occurrences.filter { $0.roles.contains(.reference) && names.contains($0.symbol.name) }.map(\.symbol.usr)))
    }

    /// Whether the indexed code makes the type conform to the protocol. Conformances of system
    /// types, such as `Int: Comparable`, are not in a project's index.
    func conforms(typeUSR: String, toProtocolUSR protocolUSR: String) -> Bool {
        protocolsByType[typeUSR]?.contains(protocolUSR) == true
    }

    /// Paths compare after symbolic links resolve: the compiler records the path it was given.
    private static func normalized(_ path: String) -> String {
        URL(fileURLWithPath: path).resolvingSymlinksInPath().path
    }
}
