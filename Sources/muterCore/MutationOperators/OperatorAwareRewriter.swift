import SwiftSyntax

class OperatorAwareRewriter: SyntaxRewriter, PositionSpecificRewriter {
    let positionToMutate: AbsolutePosition
    private(set) var description: String = ""
    
    var oppositeOperatorMapping: [String: String] = [:]
    
    required init(positionToMutate: AbsolutePosition) {
        self.positionToMutate = positionToMutate
    }
    
    override func visit(_ token: TokenSyntax) -> Syntax {
        guard token.position == positionToMutate,
            let `oppositeOperator` = oppositeOperator(for: token.tokenKind) else {
                return token
        }
        
        description = "changed \(token.description.trimmed) to \(oppositeOperator)"
        
        return mutated(token, using: `oppositeOperator`)
    }
    
    private func oppositeOperator(for tokenKind: TokenKind) -> String? {
        switch tokenKind {
        case .spacedBinaryOperator(let `operator`):
            return oppositeOperatorMapping[`operator`]
        case .ifKeyword:
            return oppositeOperatorMapping["if"]
        default:
            return nil
        }
    }
    
    private func mutated(_ token: TokenSyntax, using `operator`: String) -> Syntax {
        let mutatedTokenKind: TokenKind

        switch token.tokenKind {
        case .spacedBinaryOperator(_):
            mutatedTokenKind = .spacedBinaryOperator(`operator`)
        case .ifKeyword:
            mutatedTokenKind = .unknown(`operator`)
        default:
            mutatedTokenKind = .unknown(`operator`)
        }

        return SyntaxFactory.makeToken(
            mutatedTokenKind,
            presence: .present,
            leadingTrivia: token.leadingTrivia,
            trailingTrivia: token.trailingTrivia
        )
    }
}
