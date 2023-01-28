import SwiftSyntax

final class Rewriter: SyntaxRewriter {
    private let schemataMappings: SchemataMutationMapping

    required init(_ schemataMappings: SchemataMutationMapping) {
        self.schemataMappings = schemataMappings
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> Syntax {
        guard let mutationsInNode = schemataMappings.schematas(node) else {
            return super.visit(node)
        }

        let newNode = applyMutationSwitch(
            withOriginalSyntax: node,
            and: mutationsInNode
        )

        return super.visit(newNode)
    }
}
