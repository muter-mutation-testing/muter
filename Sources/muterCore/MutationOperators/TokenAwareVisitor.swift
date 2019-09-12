import SwiftSyntax

class TokenAwareVisitor: SyntaxVisitor, PositionDiscoveringVisitor {
    
    fileprivate(set) var tokensToDiscover = [TokenKind]()
    private(set) var positionsOfToken = [AbsolutePosition]()
    
    override func visit(_ token: TokenSyntax) {
        if canMutateToken(token) {
            positionsOfToken.append(token.position)
        }
    }

    private func canMutateToken(_ token: TokenSyntax) -> Bool {
        return tokensToDiscover.contains(token.tokenKind)
            && token.parent?.isDecl == false
    }
}

enum ROROperator {
    class Visitor: TokenAwareVisitor {
        override init() {
            super.init()
            tokensToDiscover = [
                .spacedBinaryOperator("=="),
                .spacedBinaryOperator("!="),
                .spacedBinaryOperator(">="),
                .spacedBinaryOperator("<="),
                .spacedBinaryOperator("<"),
                .spacedBinaryOperator(">"),
            ]
        }
        
        override func visit(_ node: GenericWhereClauseSyntax) {}
    }
}

enum ChangeLogicalConnectorOperator {
    class Visitor: TokenAwareVisitor {
        override init() {
            super.init()
            tokensToDiscover = [
                .spacedBinaryOperator("||"),
                .spacedBinaryOperator("&&"),
            ]
        }
    }
}
