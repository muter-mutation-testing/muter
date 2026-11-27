import CIndexStore
import Foundation

/// A symbol in the index: a type, function, operator, property, …
struct IndexSymbol: Hashable {
    /// The symbol's name, such as `>(_:_:)` or `update(part:)`.
    let name: String
    /// The unique symbol reference. For a Swift symbol it is `s:` and the mangled name, which
    /// `SwiftDemangler` turns into a signature with types.
    let usr: String
    let kind: IndexSymbolKind
}

/// The kind of a symbol, as `libIndexStore` numbers it.
struct IndexSymbolKind: RawRepresentable, Hashable {
    let rawValue: Int32

    static let `enum` = IndexSymbolKind(rawValue: 5)
    static let `struct` = IndexSymbolKind(rawValue: 6)
    static let `class` = IndexSymbolKind(rawValue: 7)
    static let `protocol` = IndexSymbolKind(rawValue: 8)
    static let `extension` = IndexSymbolKind(rawValue: 9)
    static let function = IndexSymbolKind(rawValue: 12)
    static let instanceMethod = IndexSymbolKind(rawValue: 16)
    static let classMethod = IndexSymbolKind(rawValue: 17)
    static let staticMethod = IndexSymbolKind(rawValue: 18)
    static let instanceProperty = IndexSymbolKind(rawValue: 19)
    static let constructor = IndexSymbolKind(rawValue: 22)

    var isFunction: Bool {
        [.function, .instanceMethod, .classMethod, .staticMethod, .constructor].contains(self)
    }

    var isType: Bool {
        [.enum, .struct, .class, .protocol].contains(self)
    }
}

/// What an occurrence of a symbol is, and how it relates to other symbols.
struct IndexRoles: OptionSet, Hashable {
    let rawValue: UInt64

    static let declaration = IndexRoles(rawValue: 1 << 0)
    static let definition = IndexRoles(rawValue: 1 << 1)
    static let reference = IndexRoles(rawValue: 1 << 2)
    static let call = IndexRoles(rawValue: 1 << 5)
    static let implicit = IndexRoles(rawValue: 1 << 8)
    static let childOf = IndexRoles(rawValue: 1 << 9)
    static let baseOf = IndexRoles(rawValue: 1 << 10)
    static let calledBy = IndexRoles(rawValue: 1 << 13)
    static let extendedBy = IndexRoles(rawValue: 1 << 14)
    static let containedBy = IndexRoles(rawValue: 1 << 16)
}

struct IndexRelation: Hashable {
    let roles: IndexRoles
    let symbol: IndexSymbol
}

/// One place in a source file where the compiler recorded a symbol.
struct IndexOccurrence: Hashable {
    let filePath: String
    /// The line and the UTF-8 column of the symbol's name, both from 1.
    let line: Int
    let column: Int
    let roles: IndexRoles
    let symbol: IndexSymbol
    let relations: [IndexRelation]
}

struct IndexStoreError: Error, CustomStringConvertible {
    let description: String
}

/// The index that the Swift compiler writes while it builds (`-index-store-path`), read with
/// `libIndexStore`.
final class IndexStore {
    private let library: IndexStoreLibrary
    private let store: indexstore_t

    init(path: String, library: IndexStoreLibrary) throws {
        var error: indexstore_error_t?
        guard let store = library.storeCreate(path, &error) else {
            throw IndexStoreError(description: library.message(of: error) ?? "Could not open the index store at \(path).")
        }

        self.library = library
        self.store = store
    }

    deinit {
        library.storeDispose(store)
    }

    /// Every occurrence in the Swift files under `directory`. A record that several units share is
    /// read once.
    func occurrences(inFilesUnder directory: String) -> [IndexOccurrence] {
        let prefixes = Set([directory, URL(fileURLWithPath: directory).resolvingSymlinksInPath().path])
            .map { $0.hasSuffix("/") ? $0 : $0 + "/" }

        var records: [String: String] = [:] // record name: source file path
        for unit in unitNames() {
            for (record, filePath) in recordDependencies(ofUnit: unit)
                where filePath.hasSuffix(".swift") && prefixes.contains(where: filePath.hasPrefix) {
                records[record] = filePath
            }
        }

        return records.sorted { $0.key < $1.key }.flatMap { record, filePath in
            occurrences(inRecord: record, filePath: filePath)
        }
    }

    private func unitNames() -> [String] {
        let names = Collector<String>()
        _ = library.storeUnitsApply(store, 0, names.context) { context, name in
            Collector<String>.from(context).items.append(name.string)
            return true
        }
        return names.items
    }

    private func recordDependencies(ofUnit unit: String) -> [(record: String, filePath: String)] {
        var error: indexstore_error_t?
        guard let reader = library.unitReaderCreate(store, unit, &error) else {
            library.dispose(error)
            return []
        }
        defer { library.unitReaderDispose(reader) }

        let dependencies = Collector<(record: String, filePath: String)>(library: library)
        _ = library.unitReaderDependenciesApply(reader, dependencies.context) { context, dependency in
            let collector = Collector<(record: String, filePath: String)>.from(context)
            guard let library = collector.library, let dependency,
                  library.unitDependencyGetKind(dependency) == Int32(MUTER_INDEXSTORE_UNIT_DEPENDENCY_RECORD)
            else {
                return true
            }
            collector.items.append((
                record: library.unitDependencyGetName(dependency).string,
                filePath: library.unitDependencyGetFilePath(dependency).string
            ))
            return true
        }
        return dependencies.items
    }

    private func occurrences(inRecord record: String, filePath: String) -> [IndexOccurrence] {
        var error: indexstore_error_t?
        guard let reader = library.recordReaderCreate(store, record, &error) else {
            library.dispose(error)
            return []
        }
        defer { library.recordReaderDispose(reader) }

        let occurrences = Collector<IndexOccurrence>(library: library, filePath: filePath)
        _ = library.recordReaderOccurrencesApply(reader, occurrences.context) { context, occurrence in
            let collector = Collector<IndexOccurrence>.from(context)
            guard let library = collector.library, let occurrence else {
                return true
            }
            collector.items.append(library.occurrence(occurrence, in: collector.filePath))
            return true
        }
        return occurrences.items
    }
}

/// Collects what a C callback gives. The callback gets the collector through its context pointer,
/// because a C function pointer cannot capture values.
private final class Collector<Item> {
    var items: [Item] = []
    let library: IndexStoreLibrary?
    let filePath: String

    init(library: IndexStoreLibrary? = nil, filePath: String = "") {
        self.library = library
        self.filePath = filePath
    }

    /// Valid while the collector lives: the callers keep it until the apply function returns.
    var context: UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }

    static func from(_ context: UnsafeMutableRawPointer?) -> Collector<Item> {
        Unmanaged<Collector<Item>>.fromOpaque(context!).takeUnretainedValue()
    }
}

private extension IndexStoreLibrary {
    func message(of error: indexstore_error_t?) -> String? {
        guard let error else {
            return nil
        }
        defer { errorDispose(error) }
        return errorGetDescription(error).map { String(cString: $0) }
    }

    func dispose(_ error: indexstore_error_t?) {
        if let error {
            errorDispose(error)
        }
    }

    func symbol(_ symbol: indexstore_symbol_t) -> IndexSymbol {
        IndexSymbol(
            name: symbolGetName(symbol).string,
            usr: symbolGetUSR(symbol).string,
            kind: IndexSymbolKind(rawValue: symbolGetKind(symbol))
        )
    }

    func occurrence(_ occurrence: indexstore_occurrence_t, in filePath: String) -> IndexOccurrence {
        var line: UInt32 = 0
        var column: UInt32 = 0
        occurrenceGetLineColumn(occurrence, &line, &column)

        let relations = Collector<IndexRelation>(library: self)
        _ = occurrenceRelationsApply(occurrence, relations.context) { context, relation in
            let collector = Collector<IndexRelation>.from(context)
            guard let library = collector.library, let relation,
                  let symbol = library.relationGetSymbol(relation)
            else {
                return true
            }
            collector.items.append(IndexRelation(
                roles: IndexRoles(rawValue: library.relationGetRoles(relation)),
                symbol: library.symbol(symbol)
            ))
            return true
        }

        return withExtendedLifetime(relations) {
            IndexOccurrence(
                filePath: filePath,
                line: Int(line),
                column: Int(column),
                roles: IndexRoles(rawValue: occurrenceGetRoles(occurrence)),
                symbol: occurrenceGetSymbol(occurrence).map(symbol) ?? IndexSymbol(name: "", usr: "", kind: .init(rawValue: 0)),
                relations: relations.items
            )
        }
    }
}
