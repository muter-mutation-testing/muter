import SwiftSyntax

class TokenAwareVisitor: SyntaxAnyVisitor, PositionDiscoveringVisitor {
    fileprivate(set) var tokensToDiscover = [TokenKind]()
    private(set) var positionsOfToken = [MutationPosition]()
    
    private let sourceFileInfo: SourceFileInfo

    required init(configuration: MuterConfiguration?, sourceFileInfo: SourceFileInfo) {
        self.sourceFileInfo = sourceFileInfo
    }
    
    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        node.as(TokenSyntax.self).map { node in
            if canMutateToken(node) {
                positionsOfToken.append(
                    node.mutationPosition(
                        inFile: sourceFileInfo.file,
                        withSource: sourceFileInfo.source
                    )
                )
            }
        }
        
        return .visitChildren
    }

    private func canMutateToken(_ token: TokenSyntax) -> Bool {
        tokensToDiscover.contains(token.tokenKind) &&
        token.parent?.is(BinaryOperatorExprSyntax.self) == true
    }
}

/// Relational Operator Replacement
enum ROROperator {
    class Visitor: TokenAwareVisitor {
        required init(configuration: MuterConfiguration? = nil, sourceFileInfo: SourceFileInfo) {
            super.init(configuration: configuration, sourceFileInfo: sourceFileInfo)
            tokensToDiscover = [
                .spacedBinaryOperator("=="),
                .spacedBinaryOperator("!="),
                .spacedBinaryOperator(">="),
                .spacedBinaryOperator("<="),
                .spacedBinaryOperator("<"),
                .spacedBinaryOperator(">"),
            ]
        }
        
        override func visit(_ node: GenericWhereClauseSyntax) -> SyntaxVisitorContinueKind {
            super.visit(node)
        }
    }
}

enum ChangeLogicalConnectorOperator {
    class Visitor: TokenAwareVisitor {
        required init(configuration: MuterConfiguration? = nil, sourceFileInfo: SourceFileInfo) {
            super.init(configuration: configuration, sourceFileInfo: sourceFileInfo)
            tokensToDiscover = [
                .spacedBinaryOperator("||"),
                .spacedBinaryOperator("&&"),
            ]
        }
    }
}
