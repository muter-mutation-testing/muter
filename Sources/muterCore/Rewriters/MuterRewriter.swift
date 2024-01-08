import SwiftSyntax

final class MuterRewriter: SyntaxRewriter {
    private let schemataMappings: SchemataMutationMapping
    private let configuration: MuterConfiguration

    required init(
        _ schemataMappings: SchemataMutationMapping, 
        configuration: MuterConfiguration
    ) {
        self.schemataMappings = schemataMappings
        self.configuration = configuration
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        guard let mutationSchemata = schemataMappings.schemata(node) else {
            return super.visit(node)
        }

        let newNode = MutationSwitch.apply(
            mutationSchemata: mutationSchemata,
            configuration: configuration,
            with: node
        )

        return super.visit(newNode)
    }
}
