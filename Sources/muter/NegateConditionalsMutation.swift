import SwiftSyntax

protocol PositionDiscoveringVisitor {
    var positionsOfToken: [AbsolutePosition] { get }
    func visit(_ token: TokenSyntax)
}

protocol PositionSpecificRewriter {
    var positionToMutate: AbsolutePosition { get }
    init(positionToMutate: AbsolutePosition)
    func visit(_ token: Syntax) -> Syntax
}

//func generateNegateConditionalsMutations(forFileAt path: String, withMutationsAt positions: [AbsolutePosition] ) -> [NegateConditionalsMutation] {
//    return []
//}

protocol SourceCodeMutation {
    var filePath: String { get }
    var sourceCode: SourceFileSyntax { get }
    var rewriter: PositionSpecificRewriter { get }
    func mutate()
}

protocol SourceCodeMutationDelegate {
    func writeFile(filePath: String, contents: String) throws
}

protocol dogfood {
    func sourceFromFile(at path: String) -> SourceFileSyntax?
}
struct NegateConditionalsMutation: SourceCodeMutation {

    let filePath: String
    let sourceCode: SourceFileSyntax
    let rewriter: PositionSpecificRewriter
    let delegate: SourceCodeMutationDelegate
    
    func mutate() {
        let mutatedSourceCode = rewriter.visit(sourceCode)
        try! delegate.writeFile(filePath: filePath, contents: mutatedSourceCode.description)
    }
    
    class Rewriter: SyntaxRewriter, PositionSpecificRewriter {
        let positionToMutate: AbsolutePosition
        
        required init(positionToMutate: AbsolutePosition) {
            self.positionToMutate = positionToMutate
        }
        
        override func visit(_ token: TokenSyntax) -> Syntax {
            guard case .spacedBinaryOperator("==") = token.tokenKind,
                token.position == positionToMutate else {
                return token
            }
            
            return SyntaxFactory
                .makeToken(.spacedBinaryOperator("!="),
                           presence: .present,
                           leadingTrivia: token.leadingTrivia,
                           trailingTrivia: token.trailingTrivia)
        }
    }
    
    class Visitor: SyntaxVisitor, PositionDiscoveringVisitor {
        
        private(set) var positionsOfToken = [AbsolutePosition]()
        
        override func visit(_ token: TokenSyntax) {
            guard case .spacedBinaryOperator("==") = token.tokenKind else {
                return
            }
            
            positionsOfToken.append(token.position)
        }
    }
}
