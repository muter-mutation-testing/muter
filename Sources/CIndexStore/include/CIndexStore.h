// Types and function signatures of the index store C API (libIndexStore), which reads the index
// that the Swift compiler writes while it builds. They follow clang's `indexstore/indexstore.h`,
// which Xcode does not ship. Muter does not link the library: it opens the library of the active
// toolchain at run time and looks up these functions by name, so a missing library only turns off
// the features that need it.

#ifndef MUTER_CINDEXSTORE_H
#define MUTER_CINDEXSTORE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef void *indexstore_error_t;
typedef void *indexstore_t;
typedef void *indexstore_unit_reader_t;
typedef void *indexstore_unit_dependency_t;
typedef void *indexstore_record_reader_t;
typedef void *indexstore_occurrence_t;
typedef void *indexstore_symbol_t;
typedef void *indexstore_symbol_relation_t;

typedef struct {
    const char *data;
    size_t length;
} indexstore_string_ref_t;

/// The kind of a unit dependency.
enum {
    MUTER_INDEXSTORE_UNIT_DEPENDENCY_UNIT = 1,
    MUTER_INDEXSTORE_UNIT_DEPENDENCY_RECORD = 2,
    MUTER_INDEXSTORE_UNIT_DEPENDENCY_FILE = 3,
};

typedef const char *(*muter_indexstore_error_get_description_t)(indexstore_error_t);
typedef void (*muter_indexstore_error_dispose_t)(indexstore_error_t);

typedef indexstore_t (*muter_indexstore_store_create_t)(const char *store_path, indexstore_error_t *error);
typedef void (*muter_indexstore_store_dispose_t)(indexstore_t);
typedef bool (*muter_indexstore_store_units_apply_f_t)(
    indexstore_t, unsigned sorted, void *context, bool (*applier)(void *context, indexstore_string_ref_t unit_name));

typedef indexstore_unit_reader_t (*muter_indexstore_unit_reader_create_t)(
    indexstore_t, const char *unit_name, indexstore_error_t *error);
typedef void (*muter_indexstore_unit_reader_dispose_t)(indexstore_unit_reader_t);
typedef bool (*muter_indexstore_unit_reader_dependencies_apply_f_t)(
    indexstore_unit_reader_t, void *context, bool (*applier)(void *context, indexstore_unit_dependency_t));
typedef int (*muter_indexstore_unit_dependency_get_kind_t)(indexstore_unit_dependency_t);
typedef indexstore_string_ref_t (*muter_indexstore_unit_dependency_get_name_t)(indexstore_unit_dependency_t);
typedef indexstore_string_ref_t (*muter_indexstore_unit_dependency_get_filepath_t)(indexstore_unit_dependency_t);

typedef indexstore_record_reader_t (*muter_indexstore_record_reader_create_t)(
    indexstore_t, const char *record_name, indexstore_error_t *error);
typedef void (*muter_indexstore_record_reader_dispose_t)(indexstore_record_reader_t);
typedef bool (*muter_indexstore_record_reader_occurrences_apply_f_t)(
    indexstore_record_reader_t, void *context, bool (*applier)(void *context, indexstore_occurrence_t));

typedef indexstore_symbol_t (*muter_indexstore_occurrence_get_symbol_t)(indexstore_occurrence_t);
typedef uint64_t (*muter_indexstore_occurrence_get_roles_t)(indexstore_occurrence_t);
typedef void (*muter_indexstore_occurrence_get_line_col_t)(indexstore_occurrence_t, unsigned *line, unsigned *column);
typedef bool (*muter_indexstore_occurrence_relations_apply_f_t)(
    indexstore_occurrence_t, void *context, bool (*applier)(void *context, indexstore_symbol_relation_t));

typedef int (*muter_indexstore_symbol_get_kind_t)(indexstore_symbol_t);
typedef indexstore_string_ref_t (*muter_indexstore_symbol_get_name_t)(indexstore_symbol_t);
typedef indexstore_string_ref_t (*muter_indexstore_symbol_get_usr_t)(indexstore_symbol_t);

typedef uint64_t (*muter_indexstore_symbol_relation_get_roles_t)(indexstore_symbol_relation_t);
typedef indexstore_symbol_t (*muter_indexstore_symbol_relation_get_symbol_t)(indexstore_symbol_relation_t);

#endif
