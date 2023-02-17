import SwiftSyntax

enum TernaryOperator {
    class Visitor: SyntaxAnyVisitor, PositionDiscoveringVisitor {
        private(set) var positionsOfToken: [MutationPosition] = []
        private let sourceFileInfo: SourceFileInfo
        
        required init(
            configuration: MuterConfiguration? = nil,
            sourceFileInfo: SourceFileInfo
        ) {
            self.sourceFileInfo = sourceFileInfo
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
    }
    
    final class SchemataVisitor: MutationSchemataVisitor {
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
            let snapshot = MutationOperatorSnapshot(
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

extension TernaryOperator {
    class Rewriter: SyntaxRewriter, PositionSpecificRewriter {
        var operatorSnapshot: MutationOperatorSnapshot = .null
        let positionToMutate: MutationPosition

        required init(positionToMutate: MutationPosition) {
            self.positionToMutate = positionToMutate
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
