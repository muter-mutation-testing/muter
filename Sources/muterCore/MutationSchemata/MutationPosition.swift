import SwiftSyntax

/// The position in a source file of a mutation.
struct MutationPosition: Codable, Equatable {
    /// The UTF-8 byte offset of the mutation. Used so we don't have to evaluate line wraps in order to interpret
    /// line/column pairs.
    let utf8Offset: Int

    /// The line where the mutation occurs.
    let line: Int

    /// The column where the mutation occurs.
    let column: Int

    init(
        utf8Offset: Int = 0,
        line: Int = 0,
        column: Int = 0
    ) {
        self.utf8Offset = utf8Offset
        self.line = line
        self.column = column
    }

    init(sourceLocation: SourceLocation) {
        self.init(
            utf8Offset: sourceLocation.offset,
            line: sourceLocation.line,
            column: sourceLocation.column
        )
    }
}

extension MutationPosition: Comparable {
    static func < (lhs: MutationPosition, rhs: MutationPosition) -> Bool {
        lhs.utf8Offset < rhs.utf8Offset &&
            lhs.line < rhs.line &&
            lhs.column < rhs.column
    }
}

extension MutationPosition: CustomStringConvertible {
    var description: String {
        "\(utf8Offset)_\(line)_\(column)"
    }
}

extension MutationPosition: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        MutationPosition(
            utf8Offset: \(utf8Offset),
            line: \(line),
            column: \(column)
        )
        """
    }
}

extension MutationPosition: Nullable {
    static var null: MutationPosition {
        MutationPosition(utf8Offset: 0)
    }
}

func == (lhs: MutationPosition, rhs: AbsolutePosition) -> Bool {
    lhs.utf8Offset == rhs.utf8Offset
}

func == (lhs: AbsolutePosition, rhs: MutationPosition) -> Bool {
    lhs.utf8Offset == rhs.utf8Offset
}

extension SyntaxProtocol {
    func mutationPosition(with sourceCodeInfo: SourceCodeInfo) -> MutationPosition {
        let converter = SourceLocationConverter(
            fileName: sourceCodeInfo.path,
            tree: sourceCodeInfo.code
        )

        let sourceLocation = converter.location(for: position)

        return MutationPosition(sourceLocation: sourceLocation)
    }

    func line(with sourceCodeInfo: SourceCodeInfo) -> Int {
        let converter = SourceLocationConverter(
            fileName: sourceCodeInfo.path,
            tree: sourceCodeInfo.code
        )

        let sourceLocation = startLocation(
            converter: converter
        )

        return MutationPosition(sourceLocation: sourceLocation).line
    }
}
