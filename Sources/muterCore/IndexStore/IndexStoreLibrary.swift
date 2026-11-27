import CIndexStore
import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// The functions of `libIndexStore`, loaded at run time from a toolchain. Muter does not link the
/// library, so a toolchain without it only turns off the features that need it.
final class IndexStoreLibrary {
    let errorGetDescription: muter_indexstore_error_get_description_t
    let errorDispose: muter_indexstore_error_dispose_t
    let storeCreate: muter_indexstore_store_create_t
    let storeDispose: muter_indexstore_store_dispose_t
    let storeUnitsApply: muter_indexstore_store_units_apply_f_t
    let unitReaderCreate: muter_indexstore_unit_reader_create_t
    let unitReaderDispose: muter_indexstore_unit_reader_dispose_t
    let unitReaderDependenciesApply: muter_indexstore_unit_reader_dependencies_apply_f_t
    let unitDependencyGetKind: muter_indexstore_unit_dependency_get_kind_t
    let unitDependencyGetName: muter_indexstore_unit_dependency_get_name_t
    let unitDependencyGetFilePath: muter_indexstore_unit_dependency_get_filepath_t
    let recordReaderCreate: muter_indexstore_record_reader_create_t
    let recordReaderDispose: muter_indexstore_record_reader_dispose_t
    let recordReaderOccurrencesApply: muter_indexstore_record_reader_occurrences_apply_f_t
    let occurrenceGetSymbol: muter_indexstore_occurrence_get_symbol_t
    let occurrenceGetRoles: muter_indexstore_occurrence_get_roles_t
    let occurrenceGetLineColumn: muter_indexstore_occurrence_get_line_col_t
    let occurrenceRelationsApply: muter_indexstore_occurrence_relations_apply_f_t
    let symbolGetKind: muter_indexstore_symbol_get_kind_t
    let symbolGetName: muter_indexstore_symbol_get_name_t
    let symbolGetUSR: muter_indexstore_symbol_get_usr_t
    let relationGetRoles: muter_indexstore_symbol_relation_get_roles_t
    let relationGetSymbol: muter_indexstore_symbol_relation_get_symbol_t

    private let handle: UnsafeMutableRawPointer

    /// The library of `toolchain`, or `nil` when the toolchain has none or it lacks a function.
    convenience init?(toolchain: SwiftToolchain) {
        #if os(macOS)
        let name = "libIndexStore.dylib"
        #else
        let name = "libIndexStore.so"
        #endif
        self.init(path: toolchain.libraryDirectory.appendingPathComponent(name).path)
    }

    init?(path: String) {
        guard let handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL) else {
            return nil
        }

        func load<T>(_ name: String, as type: T.Type) -> T? {
            dlsym(handle, name).map { unsafeBitCast($0, to: type) }
        }

        guard let errorGetDescription = load("indexstore_error_get_description", as: muter_indexstore_error_get_description_t.self),
              let errorDispose = load("indexstore_error_dispose", as: muter_indexstore_error_dispose_t.self),
              let storeCreate = load("indexstore_store_create", as: muter_indexstore_store_create_t.self),
              let storeDispose = load("indexstore_store_dispose", as: muter_indexstore_store_dispose_t.self),
              let storeUnitsApply = load("indexstore_store_units_apply_f", as: muter_indexstore_store_units_apply_f_t.self),
              let unitReaderCreate = load("indexstore_unit_reader_create", as: muter_indexstore_unit_reader_create_t.self),
              let unitReaderDispose = load("indexstore_unit_reader_dispose", as: muter_indexstore_unit_reader_dispose_t.self),
              let unitReaderDependenciesApply = load(
                  "indexstore_unit_reader_dependencies_apply_f",
                  as: muter_indexstore_unit_reader_dependencies_apply_f_t.self
              ),
              let unitDependencyGetKind = load("indexstore_unit_dependency_get_kind", as: muter_indexstore_unit_dependency_get_kind_t.self),
              let unitDependencyGetName = load("indexstore_unit_dependency_get_name", as: muter_indexstore_unit_dependency_get_name_t.self),
              let unitDependencyGetFilePath = load(
                  "indexstore_unit_dependency_get_filepath",
                  as: muter_indexstore_unit_dependency_get_filepath_t.self
              ),
              let recordReaderCreate = load("indexstore_record_reader_create", as: muter_indexstore_record_reader_create_t.self),
              let recordReaderDispose = load("indexstore_record_reader_dispose", as: muter_indexstore_record_reader_dispose_t.self),
              let recordReaderOccurrencesApply = load(
                  "indexstore_record_reader_occurrences_apply_f",
                  as: muter_indexstore_record_reader_occurrences_apply_f_t.self
              ),
              let occurrenceGetSymbol = load("indexstore_occurrence_get_symbol", as: muter_indexstore_occurrence_get_symbol_t.self),
              let occurrenceGetRoles = load("indexstore_occurrence_get_roles", as: muter_indexstore_occurrence_get_roles_t.self),
              let occurrenceGetLineColumn = load("indexstore_occurrence_get_line_col", as: muter_indexstore_occurrence_get_line_col_t.self),
              let occurrenceRelationsApply = load(
                  "indexstore_occurrence_relations_apply_f",
                  as: muter_indexstore_occurrence_relations_apply_f_t.self
              ),
              let symbolGetKind = load("indexstore_symbol_get_kind", as: muter_indexstore_symbol_get_kind_t.self),
              let symbolGetName = load("indexstore_symbol_get_name", as: muter_indexstore_symbol_get_name_t.self),
              let symbolGetUSR = load("indexstore_symbol_get_usr", as: muter_indexstore_symbol_get_usr_t.self),
              let relationGetRoles = load("indexstore_symbol_relation_get_roles", as: muter_indexstore_symbol_relation_get_roles_t.self),
              let relationGetSymbol = load("indexstore_symbol_relation_get_symbol", as: muter_indexstore_symbol_relation_get_symbol_t.self)
        else {
            dlclose(handle)
            return nil
        }

        self.handle = handle
        self.errorGetDescription = errorGetDescription
        self.errorDispose = errorDispose
        self.storeCreate = storeCreate
        self.storeDispose = storeDispose
        self.storeUnitsApply = storeUnitsApply
        self.unitReaderCreate = unitReaderCreate
        self.unitReaderDispose = unitReaderDispose
        self.unitReaderDependenciesApply = unitReaderDependenciesApply
        self.unitDependencyGetKind = unitDependencyGetKind
        self.unitDependencyGetName = unitDependencyGetName
        self.unitDependencyGetFilePath = unitDependencyGetFilePath
        self.recordReaderCreate = recordReaderCreate
        self.recordReaderDispose = recordReaderDispose
        self.recordReaderOccurrencesApply = recordReaderOccurrencesApply
        self.occurrenceGetSymbol = occurrenceGetSymbol
        self.occurrenceGetRoles = occurrenceGetRoles
        self.occurrenceGetLineColumn = occurrenceGetLineColumn
        self.occurrenceRelationsApply = occurrenceRelationsApply
        self.symbolGetKind = symbolGetKind
        self.symbolGetName = symbolGetName
        self.symbolGetUSR = symbolGetUSR
        self.relationGetRoles = relationGetRoles
        self.relationGetSymbol = relationGetSymbol
    }

    deinit {
        dlclose(handle)
    }
}

extension indexstore_string_ref_t {
    var string: String {
        guard let data, length > 0 else {
            return ""
        }

        return data.withMemoryRebound(to: UInt8.self, capacity: length) {
            String(decoding: UnsafeBufferPointer(start: $0, count: length), as: UTF8.self)
        }
    }
}
