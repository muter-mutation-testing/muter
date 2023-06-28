import SwiftSyntax

enum TernaryOperator {
    final class Visitor: MuterVisitor {
        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceFileInfo: SourceFileInfo
        ) {
            self.init(
                configuration: configuration,
                sourceFileInfo: sourceFileInfo,
                mutationOperatorId: .ternaryOperator
            )
        }

        override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
            let mutatedSyntax = mutated(node)
            let position = endLocation(for: node)
            let snapshot = MutationOperator.Snapshot(
                before: node.description.trimmed.inlined,
                after: mutatedSyntax.description.trimmed.inlined,
                description: "swapped ternary operator"
            )
            
            add(
                mutation: mutated(node),
                with: node,
                at: position,
                snapshot: snapshot
            )
            
            return super.visit(node)
        }

        override func visit(_ node: ExprListSyntax) -> SyntaxVisitorContinueKind {
            guard containsTernayExpression(node) else {
                return super.visit(node)
            }

            let mutatedSyntax = mutated(node)
            let position = endLocation(for: node)
            let snapshot = MutationOperator.Snapshot(
                before: node.description.trimmed.inlined,
                after: mutatedSyntax.description.trimmed.inlined,
                description: "swapped ternary operator"
            )

            add(
                mutation: mutated(node),
                with: node,
                at: position,
                snapshot: snapshot
            )

            return super.visit(node)
        }

        private func mutated(_ node: TernaryExprSyntax) -> ExprSyntax {
            ExprSyntax(
                node.withFirstChoice(
                    node.secondChoice.withTrailingTrivia(.spaces(1))
                )
                .withSecondChoice(
                    node.firstChoice.withoutTrailingTrivia()
                )
            )
        }
        
        private func mutated(_ node: ExprListSyntax) -> ExprListSyntax {
            var children = cast(node)
            guard children.contains(where: { $0.is(UnresolvedTernaryExprSyntax.self) }),
                  let index = ternaryIndex(node),
                  let ternary = children[index].as(UnresolvedTernaryExprSyntax.self)
            else {
                return node
            }
            
            let secondChoice = children[index + 1]
                .withTrailingTrivia(.spaces(1))
                .withLeadingTrivia(.spaces(1))
            let firstChoice = ternary.firstChoice
                .withTrailingTrivia(.spaces(1))
                .withLeadingTrivia(.spaces(1))
            
            children[index] = ExprSyntax(
                UnresolvedTernaryExprSyntax(firstChoice: secondChoice)
            )
            children[index + 1] = firstChoice

            return ExprListSyntax(children)
        }
        
        private func ternaryIndex(_ node: ExprListSyntax) -> Int? {
            for (index, child) in node.allChildren.enumerated() {
                if child.is(UnresolvedTernaryExprSyntax.self) {
                    return index
                }
            }

            return nil
        }

        private func cast(_ node: ExprListSyntax) -> [ExprSyntax] {
            node.allChildren.compactMap {
                $0.as(ExprSyntax.self)
            }
        }

        private func containsTernayExpression(_ node: ExprListSyntax) -> Bool {
            return node
                .allChildren
                .contains { $0.is(UnresolvedTernaryExprSyntax.self) }
        }
    }
}

//extension TernaryOperator {
//    final class Rewriter: SyntaxRewriter, PositionSpecificRewriter {
//        var operatorSnapshot: MutationOperatorSnapshot = .null
//        let positionToMutate: MutationPosition
//
//        init(positionToMutate: MutationPosition) {
//            self.positionToMutate = positionToMutate
//        }
//
//        override func visit(_ node: ExprListSyntax) -> ExprListSyntax {
//            guard node.endPosition == positionToMutate else { return super.visit(node) }
//            let children = cast(node)
//            guard children.contains(where: { $0.is(UnresolvedTernaryExprSyntax.self) }),
//                  let index = ternaryIndex(node)
//            else {
//                return super.visit(node)
//            }
//
//            let condition = children.first!
//            let ternary = TernaryExprSyntax(
//                conditionExpression: condition,
//                firstChoice: children[index + 1]
//                    .withLeadingTrivia(.spaces(1))
//                    .withTrailingTrivia(.spaces(1)),
//                secondChoice: children[index]
//                    .as(UnresolvedTernaryExprSyntax.self)!
//                    .firstChoice
//                    .withLeadingTrivia(.spaces(1))
//                    .withoutTrailingTrivia()
//            )
//
//            return ExprListSyntax([ExprSyntax(ternary)])
//        }
//
//        func ternaryIndex(_ node: ExprListSyntax) -> Int? {
//            for (index, child) in node.allChildren.enumerated() {
//                if child.is(UnresolvedTernaryExprSyntax.self) {
//                    return index
//                }
//            }
//
//            return nil
//        }
//
//        func cast(_ node: ExprListSyntax) -> [ExprSyntax] {
//            node.allChildren.compactMap {
//                $0.as(ExprSyntax.self)
//            }
//        }
//
//        override func visit(_ node: TernaryExprSyntax) -> ExprSyntax {
//            guard node.endPosition == positionToMutate else { return super.visit(node) }
//            let newNode = node.withFirstChoice(
//                node.secondChoice.withTrailingTrivia(.spaces(1))
//            )
//            .withSecondChoice(
//                node.firstChoice.withoutTrailingTrivia()
//            )
//            return super.visit(newNode)
//        }
//    }
//}
