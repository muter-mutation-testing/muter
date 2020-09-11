import SwiftSyntax

struct MutationPosition: Codable, Equatable {
    let utf8Offset: Int
    let line: Int
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
