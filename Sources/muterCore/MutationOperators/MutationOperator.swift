import SwiftSyntax

typealias SourceCodeTransformation = (Syntax) -> (mutatedSource: Syntax, description: String)
typealias RewriterInitializer = (AbsolutePosition) -> PositionSpecificRewriter
typealias VisitorInitializer = () -> PositionDiscoveringVisitor

public struct MutationPoint: Equatable, Codable {
    let mutationOperatorId: MutationOperator.Id
    let filePath: String
    let position: AbsolutePosition
}

struct MutationOperator {
    public enum Id: String, Codable, CaseIterable {
        case negateConditionals = "NegateConditionals"
        case removeSideEffects = "RemoveSideEffects"
        case logicalOperator = "ChangeLogicalConnector"
        
        var rewriterVisitorPair: (rewriter: RewriterInitializer, visitor: VisitorInitializer) {
            switch self {
            case .removeSideEffects:
               return (rewriter: RemoveSideEffectsOperator.Rewriter.init,
                       visitor: RemoveSideEffectsOperator.Visitor.init)
            case .negateConditionals:
                return (rewriter: NegateConditionalsOperator.Rewriter.init,
                        visitor: NegateConditionalsOperator.Visitor.init)
            case .logicalOperator:
                return (rewriter: LogicalOperatorOperator.Rewriter.init,
                        visitor: LogicalOperatorOperator.Visitor.init)
            }
        }
        
        func mutationOperator(for position: AbsolutePosition) -> SourceCodeTransformation {
            return { source in
                let visitor = self.rewriterVisitorPair.rewriter(position)
                let mutatedSource = visitor.visit(source)
                return (
                    mutatedSource: mutatedSource,
                    description: visitor.description
                )
            }
        }
    }
}

protocol PositionSpecificRewriter: CustomStringConvertible {
    var positionToMutate: AbsolutePosition { get }
    init(positionToMutate: AbsolutePosition)
    func visit(_ token: Syntax) -> Syntax
}

protocol PositionDiscoveringVisitor {
    var positionsOfToken: [AbsolutePosition] { get }
    func visit(_ token: SourceFileSyntax)
}
