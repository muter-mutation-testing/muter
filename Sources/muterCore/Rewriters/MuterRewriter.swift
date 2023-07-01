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

        let newNode = MutationSwitch.apply(
            mutationSchemata: mutationSchemata,
            with: node
        ).withLeadingTrivia(.spaces(1))

        return super.visit(newNode)
    }
}
