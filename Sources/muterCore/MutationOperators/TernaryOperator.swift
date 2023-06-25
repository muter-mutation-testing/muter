import SwiftSyntax

enum TernaryOperator {
    final class Visitor: SyntaxAnyVisitor, PositionDiscoveringVisitor {
        private(set) var positionsOfToken: [MutationPosition] = []
        private let sourceFileInfo: SourceFileInfo
        
        init(configuration: MuterConfiguration? = nil, sourceFileInfo: SourceFileInfo) {
            self.sourceFileInfo = sourceFileInfo
            super.init(viewMode: .all)
        }
        
        override func visit(_ node: ExprListSyntax) -> SyntaxVisitorContinueKind {
            guard containsTernayExpression(node) else {
                return super.visit(node)
            }
            
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

        override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
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
        
        private func containsTernayExpression(_ node: ExprListSyntax) -> Bool {
            return node
                .allChildren
                .contains { $0.is(UnresolvedTernaryExprSyntax.self) }
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
        
        override func visit(_ node: ExprListSyntax) -> ExprListSyntax {
            guard node.endPosition == positionToMutate else { return super.visit(node) }
            let children = cast(node)
            guard children.contains(where: { $0.is(UnresolvedTernaryExprSyntax.self) }),
                  let index = ternaryIndex(node) else {
                return super.visit(node)
            }
            
            let condition = children.first!
            let ternary = TernaryExprSyntax(
                conditionExpression: condition,
                firstChoice: children[index + 1]
                    .withLeadingTrivia(.spaces(1))
                    .withTrailingTrivia(.spaces(1)),
                secondChoice: children[index]
                    .as(UnresolvedTernaryExprSyntax.self)!
                    .firstChoice
                    .withLeadingTrivia(.spaces(1))
                    .withoutTrailingTrivia()
            )
            
            return ExprListSyntax([ExprSyntax(ternary)])
        }
        
        func ternaryIndex(_ node: ExprListSyntax) -> Int? {
            for (index, child) in node.allChildren.enumerated() {
                if child.is(UnresolvedTernaryExprSyntax.self) {
                    return index
                }
            }
            
            return nil
        }
        
        func cast(_ node: ExprListSyntax) -> [ExprSyntax] {
            node.allChildren.compactMap {
                $0.as(ExprSyntax.self)
            }
        }
        
        override func visit(_ node: TernaryExprSyntax) -> ExprSyntax {
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
