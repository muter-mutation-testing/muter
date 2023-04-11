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
                eofToken: node.eofToken
            )
        )
    }
    
    private func insertImportFoundation(
        in node: CodeBlockItemListSyntax
    ) -> CodeBlockItemListSyntax {
        node.prepending(
            CodeBlockItemSyntax(
                item: CodeBlockItemSyntax.Item(
                    ImportDeclSyntax(
                        attributes: nil,
                        modifiers: nil,
                        importTok: .importKeyword(),
                        importKind: nil,
                        path: AccessPathSyntax([
                            AccessPathComponentSyntax(
                                name: .identifier("Foundation")
                                    .appendingLeadingTrivia(.spaces(1))
                                    .appendingTrailingTrivia(.newlines(2)),
                                trailingDot: nil
                            )
                        ])
                    )
                ),
                semicolon: nil,
                errorTokens: nil
            )
        )
    }
}

final class AddImportVisitior {
    func shouldAddImportStatement(_ node: SourceFileSyntax) -> Bool {
        return !node.description.contains("import Foundation")
    }
}
