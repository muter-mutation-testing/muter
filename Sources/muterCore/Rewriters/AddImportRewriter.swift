import SwiftSyntax

final class AddImportRewriter: SyntaxRewriter {
    private let visitor = AddImportVisitior()

    private(set) var newLinesAddedToFile = 0

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        guard visitor.shouldAddImportStatement(node) else {
            return super.visit(node)
        }

        newLinesAddedToFile = 2

        return super.visit(
            SourceFileSyntax(
                statements: insertImportFoundation(in: node.statements),
                endOfFileToken: node.endOfFileToken
            )
        )
    }

    private func insertImportFoundation(
        in node: CodeBlockItemListSyntax
    ) -> CodeBlockItemListSyntax {
        var items: [CodeBlockItemSyntax] = [
            CodeBlockItemSyntax(
                item: CodeBlockItemSyntax.Item(
                    ImportDeclSyntax(
                        leadingTrivia: .space,
                        modifiers: [
                            DeclModifierSyntax(
                                name: TokenSyntax(
                                    .keyword(.import),
                                    trailingTrivia: .space,
                                    presence: .present
                                )
                            )
                        ],
                        importKeyword: .keyword(.class),
                        path: ImportPathComponentListSyntax([
                            ImportPathComponentSyntax(
                                leadingTrivia: .space,
                                name: .identifier("Foundation")
                            ),
                            ImportPathComponentSyntax(
                                name: .periodToken()
                            ),
                            ImportPathComponentSyntax(
                                name: .identifier("ProcessInfo")
                            )
                        ]),
                        trailingTrivia: .newlines(2)
                    )
                )
            )
        ]

        for item in node {
            items.append(item)
        }

        return CodeBlockItemListSyntax(items)
    }
}

final class AddImportVisitior {
    func shouldAddImportStatement(_ node: SourceFileSyntax) -> Bool {
        let allImports = node
            .description
            .split(separator: "\n")
            .include { $0.contains("import ") }
        return !allImports.any { $0.contains("Foundation") }
    }
}
