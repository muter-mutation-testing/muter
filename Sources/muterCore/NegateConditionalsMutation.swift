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

protocol SourceCodeMutation {
    var filePath: String { get }
    var sourceCode: SourceFileSyntax { get }
    var rewriter: PositionSpecificRewriter { get }
    func mutate()
}

protocol SourceCodeMutationDelegate {
    func writeFile(filePath: String, contents: String) throws
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
    
    class Delegate: SourceCodeMutationDelegate {
        func writeFile(filePath: String, contents: String) throws {
            try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
        }  
    }
    
    class Rewriter: SyntaxRewriter, PositionSpecificRewriter {
        let positionToMutate: AbsolutePosition
        private let oppositeOperatorMapping: [String: String] = [
            "==": "!=",
            "!=": "==",
            ">=": "<=",
            "<=": ">=",
            ">": "<",
            "<": ">"
        ]

        required init(positionToMutate: AbsolutePosition) {
            self.positionToMutate = positionToMutate
        }
        
        override func visit(_ token: TokenSyntax) -> Syntax {
            guard token.position == positionToMutate, 
                let `oppositeOperator` = oppositeOperator(for: token.tokenKind) else {
                    return token
            }
            return mutated(token, using: `oppositeOperator`)
        }

        private func oppositeOperator(for tokenKind: TokenKind) -> String? {
            guard case .spacedBinaryOperator(let `operator`) = tokenKind else {
                return nil
            }
            
            return oppositeOperatorMapping[`operator`]
        }

        private func mutated(_ token: TokenSyntax, using `operator`: String) -> Syntax {
            return SyntaxFactory.makeToken(
                .spacedBinaryOperator(`operator`),
                presence: .present,
                leadingTrivia: token.leadingTrivia,
                trailingTrivia: token.trailingTrivia
            )
        }
    }
    
    class Visitor: SyntaxVisitor, PositionDiscoveringVisitor {
        private let tokens: [TokenKind] = [
            .spacedBinaryOperator("=="),
            .spacedBinaryOperator("!="),
            .spacedBinaryOperator(">="),
            .spacedBinaryOperator("<="),
            .spacedBinaryOperator("<"),
            .spacedBinaryOperator(">"),
        ]
        
        private(set) var positionsOfToken = [AbsolutePosition]()
        
        override func visit(_ token: TokenSyntax) {
            guard tokens.contains(token.tokenKind) else {
                return
            }
            
            positionsOfToken.append(token.position)
        }
    }
}
