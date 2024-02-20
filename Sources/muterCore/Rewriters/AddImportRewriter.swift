import SwiftSyntax

final class AddImportRewriter: SyntaxRewriter {
    private let visitor = AddImportVisitior()

    private(set) var newLinesAddedToFile = 0

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        visitor.walk(node)

        guard !visitor.isImportingFoundation else {
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

final class AddImportVisitior: SyntaxAnyVisitor {
    private(set) var isImportingFoundation = false

    init() {
        super.init(viewMode: .all)
    }

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        if isImportingProcessInfo(node) || isImportingFoundation(node) {
            isImportingFoundation = true
        }

        return super.visit(node)
    }

    private func isImportingFoundation(_ node: ImportDeclSyntax) -> Bool {
        node.path.count == 1 && node.path.first?.name.text == "Foundation"
    }

    private func isImportingProcessInfo(_ node: ImportDeclSyntax) -> Bool {
        node.description.contains("Foundation.ProcessInfo")
    }
}
