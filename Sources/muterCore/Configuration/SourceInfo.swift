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
}

extension SourceCodeInfo {
    var asSourceFileInfo: SourceFileInfo {
        .init(
            path: path,
            source: code.description
        )
    }
}
