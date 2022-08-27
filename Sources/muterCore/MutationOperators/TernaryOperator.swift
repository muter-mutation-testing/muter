import SwiftSyntax

enum TernaryOperator {
    final class Visitor: SyntaxAnyVisitor, PositionDiscoveringVisitor {
        private(set) var positionsOfToken: [MutationPosition] = []
        private let sourceFileInfo: SourceFileInfo
        
        init(configuration: MuterConfiguration? = nil, sourceFileInfo: SourceFileInfo) {
            self.sourceFileInfo = sourceFileInfo
        }
        
        public override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
            let converter = SourceLocationConverter(
                file: sourceFileInfo.path,
                source: sourceFileInfo.source
            )
            let sourceLocation = node.endLocation(
                converter: converter,
                afterTrailingTrivia: true
            )
            positionsOfToken.append(.init(sourceLocation: sourceLocation))
            return super.visit(node)
        }
    }
}

extension TernaryOperator {
    final class Rewriter: SyntaxRewriter, PositionSpecificRewriter {
        var operatorSnapshot: MutationOperatorSnapshot = .null
        let positionToMutate: MutationPosition

        init(positionToMutate: MutationPosition) {
            self.positionToMutate = positionToMutate
        }

        public override func visit(_ node: TernaryExprSyntax) -> ExprSyntax {
            guard node.endPosition == positionToMutate else { return super.visit(node) }
            let newNode = node.withFirstChoice(
                node.secondChoice.withTrailingTrivia(.spaces(1))
            )
            .withSecondChoice(
                node.firstChoice.withoutTrailingTrivia()
            )
            return super.visit(newNode)
        }
    }
}
