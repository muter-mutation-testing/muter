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

private extension SequenceExprSyntax {
    var isInsideCompilerDirective: Bool {
        parent?.is(IfConfigClauseSyntax.self) == true
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
