import SwiftSyntax

enum NegateConditionalsOperator {
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

extension NegateConditionalsOperator {
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
}
