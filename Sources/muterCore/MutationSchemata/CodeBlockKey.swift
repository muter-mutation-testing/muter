import SwiftSyntax

struct CodeBlockKey: Hashable {
    let utf8Offset: Int
    let utf8Length: Int
    let description: String

    init(_ node: CodeBlockItemListSyntax) {
        utf8Offset = node.position.utf8Offset
        utf8Length = node.totalLength.utf8Length
        description = node.description
    }

    /// Hash/equality based on position only — stable across re-parses
    static func == (lhs: CodeBlockKey, rhs: CodeBlockKey) -> Bool {
        lhs.utf8Offset == rhs.utf8Offset && lhs.utf8Length == rhs.utf8Length
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(utf8Offset)
        hasher.combine(utf8Length)
    }
}
