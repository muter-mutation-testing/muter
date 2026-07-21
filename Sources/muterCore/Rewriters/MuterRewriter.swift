import SwiftSyntax

final class MuterRewriter: SyntaxRewriter {
    private let schemataMappings: SchemataMutationMapping

    required init(_ schemataMappings: SchemataMutationMapping) {
        self.schemataMappings = schemataMappings
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        // Visit children FIRST (bottom-up) so inner code blocks get their
        // mutation switches while their SyntaxIdentifiers still match the
        // dictionary keys. Applying the outer switch first (top-down) creates
        // a new syntax tree that changes all inner node IDs, breaking lookups.
        let visitedNode = super.visit(node)

        guard let mutationSchemata = schemataMappings.schemata(node) else {
            return visitedNode
        }

        return MutationSwitch.apply(
            mutationSchemata: mutationSchemata,
            with: visitedNode
        )
    }
}
