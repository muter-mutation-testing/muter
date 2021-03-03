import SwiftSyntax

/// The position in a source file of a mutation.
struct MutationPosition: Codable, Equatable {
    /// The UTF-8 byte offset of the mutation. Used so we don't have to evaluate line wraps in order to interpret
    /// line/column pairs.
    let utf8Offset: Int

    /// The line where the mutation occurs.
    let line: Int

    /// The column where the mutation occurs.s
    let column: Int

    init(utf8Offset: Int, line: Int = 0, column: Int = 0) {
        self.utf8Offset = utf8Offset
        self.line = line
        self.column = column
    }
    
    init(sourceLocation: SourceLocation) {
        self.init(
            utf8Offset: sourceLocation.offset,
            line: sourceLocation.line ?? 0,
            column: sourceLocation.column ?? 0
        )
    }
}

extension MutationPosition: Nullable {
    static var null: MutationPosition {
        MutationPosition(utf8Offset: -999)
    }
}

func == (lhs: MutationPosition, rhs: AbsolutePosition) -> Bool {
    lhs.utf8Offset == rhs.utf8Offset
}

func == (lhs: AbsolutePosition, rhs: MutationPosition) -> Bool {
    lhs.utf8Offset == rhs.utf8Offset
}

extension SyntaxProtocol {
    func mutationPosition(with sourceFileInfo: SourceFileInfo) -> MutationPosition {
        let converter = SourceLocationConverter(
            file: sourceFileInfo.path,
            source: sourceFileInfo.source
        )

        let sourceLocation = SourceLocation(
            offset: position.utf8Offset,
            converter: converter
        )

        return MutationPosition(sourceLocation: sourceLocation)
    }
}
