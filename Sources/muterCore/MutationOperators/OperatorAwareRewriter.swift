import SwiftSyntax

class OperatorAwareRewriter: SyntaxRewriter, PositionSpecificRewriter {
    let positionToMutate: MutationPosition
    var operatorSnapshot: MutationOperatorSnapshot = .null
    var currentExpression: String = ""
    
    var oppositeOperatorMapping: [String: String] = [:]
    
    required init(positionToMutate: MutationPosition) {
        self.positionToMutate = positionToMutate
    }

    override func visit(_ token: TokenSyntax) -> Syntax {
        guard token.position == positionToMutate,
            let oppositeOperator = oppositeOperator(for: token.tokenKind) else {
                return Syntax(token)
        }

        operatorSnapshot = MutationOperatorSnapshot(
            before: token.description.trimmed,
            after: oppositeOperator,
            description: "changed \(token.description.trimmed) to \(oppositeOperator)"
        )

        return mutated(token, using: oppositeOperator)
    }
    
    private func oppositeOperator(for tokenKind: TokenKind) -> String? {
        guard case .spacedBinaryOperator(let `operator`) = tokenKind else {
            return nil
        }
        
        return oppositeOperatorMapping[`operator`]
    }
    
    private func mutated(_ token: TokenSyntax, using `operator`: String) -> Syntax {
        let tokenSyntax = SyntaxFactory.makeToken(
            .spacedBinaryOperator(`operator`),
            presence: .present,
            leadingTrivia: token.leadingTrivia,
            trailingTrivia: token.trailingTrivia
        )
        return Syntax(tokenSyntax)
    }
}
