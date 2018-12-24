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
