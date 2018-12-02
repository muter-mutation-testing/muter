import SwiftSyntax

protocol SourceCodeMutation {
    func canMutate(source: SourceFileSyntax) -> Bool
    func mutate(source: SourceFileSyntax) -> Syntax
    var numberOfMutations: Int { get }
}

class NegateConditionalsMutation: SourceCodeMutation {
    
    private class Rewriter: SyntaxRewriter {
        private(set) var numberOfMutations: Int = 0
        override func visit(_ token: TokenSyntax) -> Syntax {
            
            guard case .spacedBinaryOperator("==") = token.tokenKind else {
                return token
            }
            numberOfMutations += 1
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
    
    private(set) var numberOfMutations: Int = 0
    
    func canMutate(source: SourceFileSyntax) -> Bool {
        let visitor = Visitor()
        visitor.visit(source)
        return visitor.sourceContainsMutableToken
    }
    
    func mutate(source: SourceFileSyntax) -> Syntax {
        let rewriter = Rewriter()
        let mutatedSource = rewriter.visit(source)
        numberOfMutations = rewriter.numberOfMutations
        return mutatedSource
    }
}
