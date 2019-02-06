import SwiftSyntax

extension AbsolutePosition: Equatable {
    public static func == (lhs: AbsolutePosition, rhs: AbsolutePosition) -> Bool {
        return (lhs.column, lhs.line, lhs.utf8Offset) == (rhs.column, rhs.line, rhs.utf8Offset)
    }
}

extension AbsolutePosition: Encodable {

    enum Keys: CodingKey {
        case line
        case column
        case utf8Offset
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(line, forKey: .line)
        try container.encode(column, forKey: .column)
        try container.encode(utf8Offset, forKey: .utf8Offset)
    }
}
