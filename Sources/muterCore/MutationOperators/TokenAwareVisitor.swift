import SwiftSyntax

class TokenAwareVisitor: SyntaxAnyVisitor, PositionDiscoveringVisitor {
    var tokensToDiscover = [TokenKind]()
    var positionsOfToken = [MutationPosition]()
    
    private let sourceFileInfo: SourceFileInfo

    required init(
        configuration: MuterConfiguration?,
        sourceFileInfo: SourceFileInfo
    ) {
        self.sourceFileInfo = sourceFileInfo
    }
    
    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        node.as(TokenSyntax.self).map { node in
            if canMutateToken(node) {
                positionsOfToken.append(
                    node.mutationPosition(with: sourceFileInfo)
                )
            }
        }
        
        return .visitChildren
    }
    
    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        node.isInsideCompilerDirective
            ? .skipChildren
            : .visitChildren
    }

    private func canMutateToken(_ token: TokenSyntax) -> Bool {
        tokensToDiscover.contains(token.tokenKind) &&
        token.parent?.is(BinaryOperatorExprSyntax.self) == true
    }
}

class TokenAwareSchemataVisitor: MutationSchemataVisitor {
    var tokensToDiscover = [TokenKind]()
    var oppositeOperatorMapping: [String: String] = [:]
    
    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        guard let node = node.as(TokenSyntax.self),
              canMutateToken(node),
              let oppositeOperator = oppositeOperator(for: node.tokenKind) else {
            return .visitChildren
        }
        
        let positionInSourceCode = node.mutationPosition(with: sourceFileInfo)
        let mutation = Schemata(
            id: makeSchemataId(sourceFileInfo, positionInSourceCode),
            syntaxMutation: transform(
                node: node,
                mutatedSyntax: mutated(node, using: oppositeOperator)
            ),
            positionInSourceCode: positionInSourceCode,
            snapshot: MutationOperatorSnapshot(
                before: node.description.trimmed,
                after: oppositeOperator,
                description: "changed \(node.description.trimmed) to \(oppositeOperator)"
            )
        )
        
        schemataMappings.add(
            node.codeBlockItemListSyntax,
            mutation
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
}


private extension SequenceExprSyntax {
    var isInsideCompilerDirective: Bool {
        parent?.is(IfConfigClauseSyntax.self) == true
    }
}
