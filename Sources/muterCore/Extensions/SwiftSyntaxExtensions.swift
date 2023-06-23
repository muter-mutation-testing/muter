import SwiftSyntax

extension SyntaxProtocol {
    var allChildren: SyntaxChildren {
        children(viewMode: .all)
    }
}
