import SwiftSyntax

/// Changes `true` to `false` and `false` to `true`.
///
/// Removing a line that sets a value its default already has goes unnoticed (#140), so a
/// `RemoveSideEffects` mutant survives even when the value matters. Swapping the literal shows
/// whether the tests check the value.
enum SwapBooleanLiteralOperator {
    final class Visitor: MuterVisitor {
        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceCodeInfo: SourceCodeInfo,
            regionsWithoutCoverage: [Region] = []
        ) {
            self.init(
                configuration: configuration,
                sourceCodeInfo: sourceCodeInfo,
                mutationOperatorId: .swapBooleanLiteral,
                regionsWithoutCoverage: regionsWithoutCoverage
            )
        }

        override func visit(_ node: BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind {
            guard node.isInsideABody, !node.isInsideCompilerDirective else {
                return super.visit(node)
            }

            let swapped: Keyword = node.literal.tokenKind == .keyword(.true) ? .false : .true
            let before = node.literal.text
            let after = TokenSyntax.keyword(swapped).text

            add(
                mutation: TokenSyntax.keyword(swapped),
                with: node,
                at: startLocation(for: node),
                snapshot: MutationOperator.Snapshot(
                    before: before,
                    after: after,
                    description: "changed \(before) to \(after)"
                )
            )

            return super.visit(node)
        }

        /// Replaces exactly this literal. The default transform looks for the first match of the node's
        /// text in the statement list, and `true` or `false` often appears more than once there. The
        /// range has the length of the original literal, because `true` and `false` differ in length.
        override func transform(
            node: SyntaxProtocol,
            mutatedSyntax: SyntaxProtocol,
            at mutationRange: Range<String.Index>? = nil
        ) -> String {
            guard let literal = Syntax(node).as(BooleanLiteralExprSyntax.self)?.literal else {
                return super.transform(node: node, mutatedSyntax: mutatedSyntax, at: mutationRange)
            }

            let codeBlock = node.codeBlockItemListSyntax
            let codeBlockDescription = codeBlock.description
            let utf8Offset = literal.positionAfterSkippingLeadingTrivia.utf8Offset - codeBlock.position.utf8Offset

            guard let start = codeBlockDescription.convertToCharOffset(from: utf8Offset) else {
                return super.transform(node: node, mutatedSyntax: mutatedSyntax, at: mutationRange)
            }

            let lowerBound = codeBlockDescription.index(codeBlockDescription.startIndex, offsetBy: start)
            let upperBound = codeBlockDescription.index(lowerBound, offsetBy: literal.text.count)

            return super.transform(node: node, mutatedSyntax: mutatedSyntax, at: lowerBound ..< upperBound)
        }
    }
}

private extension BooleanLiteralExprSyntax {
    /// Muter does not mutate code in compiler directives (`#if`).
    var isInsideCompilerDirective: Bool {
        var current = parent
        while let node = current, !node.is(CodeBlockItemSyntax.self) {
            if node.is(IfConfigClauseSyntax.self) {
                return true
            }
            current = node.parent
        }

        return false
    }
}
