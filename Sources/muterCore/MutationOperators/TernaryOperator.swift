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
            
            return .visitChildren
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
    }
}
