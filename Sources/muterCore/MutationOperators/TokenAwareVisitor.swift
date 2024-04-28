import SwiftSyntax

class TokenAwareVisitor: MuterVisitor {
    var tokensToDiscover = [TokenKind]()
    var oppositeOperatorMapping: [String: String] = [:]

    override func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let `operator` = node.operator
        guard canMutateToken(`operator`),
              let oppositeOperator = oppositeOperator(for: `operator`.tokenKind)
        else {
            return .visitChildren
        }

        let position = startLocation(for: node)
        let snapshot = MutationOperator.Snapshot(
            before: node.description.trimmed,
            after: oppositeOperator,
            description: "changed \(node.description.trimmed) to \(oppositeOperator)"
        )

        add(
            mutation: mutated(
                `operator`,
                using: oppositeOperator
            ),
            with: node,
            at: position,
            snapshot: snapshot
        )

        return super.visit(node)
    }

    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        node.isInsideCompilerDirective
            ? .skipChildren
            : .visitChildren
    }

    private func oppositeOperator(for tokenKind: TokenKind) -> String? {
        guard case let .binaryOperator(`operator`) = tokenKind else {
            return nil
        }

        return oppositeOperatorMapping[`operator`]
    }

    private func canMutateToken(_ token: TokenSyntax) -> Bool {
        tokensToDiscover.contains(token.tokenKind) &&
            token.parent?.is(BinaryOperatorExprSyntax.self) == true
    }

    private func mutated(
        _ token: TokenSyntax,
        using operator: String
    ) -> Syntax {
        let tokenSyntax = TokenSyntax(
            .binaryOperator(`operator`),
            leadingTrivia: token.leadingTrivia,
            trailingTrivia: token.trailingTrivia,
            presence: .present
        )

        return Syntax(tokenSyntax)
    }

    override func transform(
        node: SyntaxProtocol,
        mutatedSyntax: SyntaxProtocol,
        at mutationRange: Range<String.Index>? = nil
    ) -> CodeBlockItemListSyntax {
        let codeBlockItemListSyntax = node.codeBlockItemListSyntax
        let codeBlockDescription = codeBlockItemListSyntax.description
        let utf8Offset = node.offsetInCodeBlockItemListSyntax(sourceCodeInfo)

        guard let nodePositionOffset = codeBlockDescription.convertToCharOffset(from: utf8Offset) else {
            return super.transform(node: node, mutatedSyntax: mutatedSyntax, at: mutationRange)
        }

        let nodeStartRange = codeBlockDescription.index(
            codeBlockDescription.startIndex,
            offsetBy: nodePositionOffset
        )

        let nodeEndRange = codeBlockDescription.index(
            codeBlockDescription.startIndex,
            offsetBy: nodePositionOffset + mutatedSyntax.description.count
        )
        let mutationRangeInCodeBlock = nodeStartRange ..< nodeEndRange

        return super.transform(
            node: node,
            mutatedSyntax: mutatedSyntax,
            at: mutationRangeInCodeBlock
        )
    }
}

private extension SyntaxProtocol {
    func offsetInCodeBlockItemListSyntax(_ sourceCode: SourceCodeInfo) -> Int {
        let nodePosition = mutationPosition(with: sourceCode)
        let codeBlockItemListSyntax = codeBlockItemListSyntax.mutationPosition(with: sourceCode)

        return nodePosition.utf8Offset - codeBlockItemListSyntax.utf8Offset
    }
}

private extension SequenceExprSyntax {
    var isInsideCompilerDirective: Bool {
        parent?.is(IfConfigClauseSyntax.self) == true
    }
}
