import SwiftSyntax

final class DisableLintersRewriter: SyntaxRewriter {
    private(set) var newLinesAddedToFile = 3

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        super.visit(
            SourceFileSyntax(
                statements: disableLinters(in: node.statements),
                eofToken: node.eofToken
            )
        )
    }

    private func disableLinters(
        in node: CodeBlockItemListSyntax
    ) -> CodeBlockItemListSyntax {
        let disableLinters = """
        // swiftformat:disable all
        // swiftlint:disable all
        """

        return node.appendingLeadingTrivia(
            .lineComment(disableLinters),
            .newlines(2)
        )
    }
}
