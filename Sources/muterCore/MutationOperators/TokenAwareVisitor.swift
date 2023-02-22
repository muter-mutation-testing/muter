import SwiftSyntax

class TokenAwareVisitor: MuterVisitor {
    var tokensToDiscover = [TokenKind]()
    var oppositeOperatorMapping: [String: String] = [:]
    
    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        guard let node = node.as(TokenSyntax.self),
              canMutateToken(node),
              let oppositeOperator = oppositeOperator(for: node.tokenKind) else {
            return .visitChildren
        }
        
        let position = location(for: node)
        let snapshot = MutationOperator.Snapshot(
            before: node.description.trimmed,
            after: oppositeOperator,
            description: "changed \(node.description.trimmed) to \(oppositeOperator)"
        )
        
        add(
            mutation: mutated(
                node,
                using: oppositeOperator
            ),
            with: node,
            at: position,
            snapshot: snapshot
        )
        
        return .visitChildren
    }
    
    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        node.isInsideCompilerDirective
            ? .skipChildren
            : .visitChildren
    }
    
    private func oppositeOperator(for tokenKind: TokenKind) -> String? {
        guard case .spacedBinaryOperator(let `operator`) = tokenKind else {
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
        using `operator`: String
    ) -> Syntax {
        let tokenSyntax = SyntaxFactory.makeToken(
            .spacedBinaryOperator(`operator`),
            presence: .present,
            leadingTrivia: token.leadingTrivia,
            trailingTrivia: token.trailingTrivia
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
        let nodePosition = node.offsetInCodeBlockItemListSyntax(sourceFileInfo)
        let nodeStartRange = codeBlockDescription.index(codeBlockDescription.startIndex, offsetBy: nodePosition)
        let nodeEndRange = codeBlockDescription.index(codeBlockDescription.startIndex, offsetBy: nodePosition + mutatedSyntax.description.count)
        let mutationRangeInCodeBlock = nodeStartRange..<nodeEndRange
        
        return super.transform(
            node: node,
            mutatedSyntax: mutatedSyntax,
            at: mutationRangeInCodeBlock
        )
    }
}

private extension SyntaxProtocol {
    func offsetInCodeBlockItemListSyntax(_ sourceCode: SourceFileInfo) -> Int {
        let nodePosition = mutationPosition(
            with: sourceCode
        )

        let codeBlockItemListSyntax = codeBlockItemListSyntax.mutationPosition(
            with: sourceCode
        )
        
        return nodePosition.utf8Offset - codeBlockItemListSyntax.utf8Offset
    }
}

private extension SequenceExprSyntax {
    var isInsideCompilerDirective: Bool {
        parent?.is(IfConfigClauseSyntax.self) == true
    }
}
