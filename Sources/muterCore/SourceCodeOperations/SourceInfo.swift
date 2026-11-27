import Foundation
import SwiftSyntax

/// The full path to a file on disk, and its complete contents as a string.
struct SourceFileInfo {

    /// The path to the file on disk.
    let path: String

    /// The full contents of the file.
    let source: String
}

/// The full path to a file on disk, and its complete contents as a SourceFileSyntax.
struct SourceCodeInfo {

    /// The path to the file on disk.
    let path: String

    /// The full contents of the file as a syntax tree.
    let code: SourceFileSyntax

    /// Values computed once for each file and shared by every operator's visitor. A
    /// `SourceLocationConverter` builds a line table for the whole file, so making one for each
    /// node used to allocate the table again and again.
    private let cache = FileCache()

    init(path: String, code: SourceFileSyntax) {
        self.path = path
        self.code = code
    }

    var locationConverter: SourceLocationConverter {
        cache.value(\.converter) {
            SourceLocationConverter(fileName: path, tree: code)
        }
    }

    var disableDirectives: DisableDirectives {
        cache.value(\.disableDirectives) {
            DisableDirectives(source: code, fileName: path, converter: locationConverter)
        }
    }
}

private final class FileCache {
    private let lock = NSLock()
    var converter: SourceLocationConverter?
    var disableDirectives: DisableDirectives?

    func value<T>(_ keyPath: ReferenceWritableKeyPath<FileCache, T?>, make: () -> T) -> T {
        lock.lock()
        if let value = self[keyPath: keyPath] {
            lock.unlock()
            return value
        }
        lock.unlock()

        // Made outside the lock: `make` can read another cached value.
        let value = make()
        lock.lock()
        defer { lock.unlock() }
        if let existing = self[keyPath: keyPath] {
            return existing
        }
        self[keyPath: keyPath] = value
        return value
    }
}

extension SourceCodeInfo {
    var asSourceFileInfo: SourceFileInfo {
        .init(
            path: path,
            source: code.description
        )
    }
}
