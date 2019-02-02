import SwiftSyntax

public extension AbsolutePosition {
    public static var firstPosition: AbsolutePosition {
        return AbsolutePosition(line: 0, column: 0, utf8Offset: 0)
    }
}

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
