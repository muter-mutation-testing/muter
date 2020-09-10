import SwiftSyntax

class TokenAwareVisitor: SyntaxAnyVisitor, PositionDiscoveringVisitor {
    var file: String
    var source: String

    fileprivate(set) var tokensToDiscover = [TokenKind]()
    private(set) var positionsOfToken = [MutationPosition]()

    required init(configuration: MuterConfiguration? = nil, file: String, source: String) {
        self.file = file
        self.source = source
    }
    
    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        node.as(TokenSyntax.self).map { node in
            if canMutateToken(node) {
                positionsOfToken.append(node.mutationPosition(inFile: file, withSource: source))
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
        required init(configuration: MuterConfiguration? = nil, file: String, source: String) {
            super.init(configuration: configuration, file: file, source: source)
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
        required init(configuration: MuterConfiguration? = nil, file: String, source: String) {
            super.init(configuration: configuration, file: file, source: source)
            tokensToDiscover = [
                .spacedBinaryOperator("||"),
                .spacedBinaryOperator("&&"),
            ]
        }
    }
}
