import SwiftSyntax

class NegateConditionalsMutation {
    
    private class Rewriter: SyntaxRewriter {
        override func visit(_ token: TokenSyntax) -> Syntax {
            
            guard case .spacedBinaryOperator("==") = token.tokenKind else {
                return token
            }
            
            return SyntaxFactory.makeToken(.spacedBinaryOperator("!="),
                                           presence: .present,
                                           leadingTrivia: token.leadingTrivia,
                                           trailingTrivia: token.trailingTrivia
            )
        }
    }
    
    func mutate(source: SourceFileSyntax) -> Syntax {
        return Rewriter().visit(source)
    }
}
