import SwiftSyntax

final class AddImportRewriter: SyntaxRewriter {
    private let visitor = AddImportVisitior()
    
    private(set) var newLinesAddedToFile = 0

    override func visit(_ node: SourceFileSyntax) -> Syntax {
        guard visitor.shouldAddImportStatement(node) else {
            return super.visit(node)
        }

        newLinesAddedToFile = 2
        
        return super.visit(
            SyntaxFactory.makeSourceFile(
                statements: insertImportFoundation(in: node.statements),
                eofToken: node.eofToken
            )
        )
    }
    
    private func insertImportFoundation(
        in node: CodeBlockItemListSyntax
    ) -> CodeBlockItemListSyntax {
        node.prepending(
            SyntaxFactory.makeCodeBlockItem(
                item: Syntax(
                    SyntaxFactory.makeImportDecl(
                        attributes: nil,
                        modifiers: nil,
                        importTok: SyntaxFactory.makeImportKeyword(),
                        importKind: nil,
                        path: SyntaxFactory.makeAccessPath([
                            SyntaxFactory.makeAccessPathComponent(
                                name: SyntaxFactory.makeIdentifier("Foundation")
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
