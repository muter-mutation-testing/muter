import SwiftSyntax
@testable import muterCore

extension MutationPosition {
    public static var firstPosition: MutationPosition {
        return MutationPosition(utf8Offset: 0, line: 0, column: 0)
    }
}
