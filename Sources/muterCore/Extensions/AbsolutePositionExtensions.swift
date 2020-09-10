import SwiftSyntax

struct MutationPosition: Codable, Equatable {
    let utf8Offset: Int
    let line: Int
    let column: Int

    init(utf8Offset: Int, line: Int? = nil, column: Int? = nil) {
        self.utf8Offset = utf8Offset
        self.line = line ?? 0
        self.column = column ?? 0
    }
    
    init(sourceLocation: SourceLocation) {
        self.init(
            utf8Offset: sourceLocation.offset,
            line: sourceLocation.line,
            column: sourceLocation.column
        )
    }
}

func == (lhs: MutationPosition, rhs: AbsolutePosition) -> Bool {
    lhs.utf8Offset == rhs.utf8Offset
}

func == (lhs: AbsolutePosition, rhs: MutationPosition) -> Bool {
    lhs.utf8Offset == rhs.utf8Offset
}

extension AbsolutePosition: Codable {
    enum Keys: CodingKey {
        case utf8Offset
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)

        let utf8Offset = try container.decode(Int.self, forKey: .utf8Offset)

        self.init(utf8Offset: utf8Offset)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)

        try container.encode(utf8Offset, forKey: .utf8Offset)
    }
}

extension SyntaxProtocol {
    func mutationPosition(inFile file: String, withSource source: String) -> MutationPosition {
        let converter = SourceLocationConverter(
            file: file,
            source: source
        )

        let sourceLocation = SourceLocation(
            offset: position.utf8Offset,
            converter: converter
        )

        return MutationPosition(sourceLocation: sourceLocation)
    }
}
