import SwiftSyntax

final class MuterRewriter: SyntaxRewriter {
    private let schemataMappings: SchemataMutationMapping

    required init(_ schemataMappings: SchemataMutationMapping) {
        self.schemataMappings = schemataMappings
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        guard let mutationSchemata = schemataMappings.schemata(node) else {
            return super.visit(node)
        }

        // Rewrite the CHILDREN first, on the original node, then wrap the result.
        //
        // Applying the switch first and visiting the synthesized node loses every nested code block's
        // mutants: wrapping shifts the nested blocks' source positions, so their mapping entries no
        // longer match and their switches are silently never inserted. A closure or ternary body
        // therefore had mutants discovered and then dropped. Visiting the original node keeps the
        // nested positions the discovery pass recorded, and the rewritten children become the switch's
        // default branch.
        let childrenRewritten = super.visit(node)

        return MutationSwitch.apply(
            mutationSchemata: mutationSchemata,
            with: childrenRewritten
        )
    }
}
