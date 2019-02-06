import SwiftSyntax

extension AbsolutePosition {
    public static var firstPosition: AbsolutePosition {
        return AbsolutePosition(line: 0, column: 0, utf8Offset: 0)
    }
}
