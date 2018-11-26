import SwiftSyntax

protocol SourceCodeMutation {
    func canMutate(source: SourceFileSyntax) -> Bool
    func mutate(source: SourceFileSyntax) -> Syntax
}

class NegateConditionalsMutation: SourceCodeMutation {
    
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
    
    private class Visitor: SyntaxVisitor {
        private(set) var sourceContainsMutableToken = false
        
        override func visit(_ token: TokenSyntax) {
            
            guard case .spacedBinaryOperator("==") = token.tokenKind else {
                return
            }
            
            sourceContainsMutableToken = true
        }
    }
    
    func canMutate(source: SourceFileSyntax) -> Bool {
        let visitor = Visitor()
        visitor.visit(source)
        return visitor.sourceContainsMutableToken
    }
    
    func mutate(source: SourceFileSyntax) -> Syntax {
        return Rewriter().visit(source)
    }
}
