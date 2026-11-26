import SwiftSyntax

extension SyntaxProtocol {
    /// A mutant replaces the statement list that holds the node. Outside a function, closure,
    /// accessor or switch-case body that list is the file's top level, where an `if` that wraps a type
    /// declaration or a stored property does not compile. So only nodes inside a body are mutated.
    ///
    /// The statement list of an `#if` clause decides nothing: it is a body only when the `#if` itself
    /// is inside one. Many files wrap all their code in `#if os(…)`.
    var isInsideABody: Bool {
        var current = parent
        while let node = current {
            if let list = node.as(CodeBlockItemListSyntax.self), let owner = list.parent {
                if owner.is(SourceFileSyntax.self) {
                    return false
                }
                if !owner.is(IfConfigClauseSyntax.self) {
                    return true
                }
            }
            current = node.parent
        }

        return false
    }
}
