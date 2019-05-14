import SwiftSyntax

typealias SourceCodeTransformation = (Syntax) -> (mutatedSource: Syntax, description: String)
typealias MutationIdVisitorPair = (id: MutationOperator.Id, visitor: VisitorInitializer)
typealias RewriterInitializer = (AbsolutePosition) -> PositionSpecificRewriter
typealias VisitorInitializer = () -> PositionDiscoveringVisitor

public struct MutationOperator {

    let id: Id
    let filePath: String
    let position: AbsolutePosition
    private let source: Syntax
    private let transformation: SourceCodeTransformation

    init(id: Id, filePath: String, position: AbsolutePosition, source: Syntax, transformation: @escaping SourceCodeTransformation) {
        self.id = id
        self.filePath = filePath
        self.position = position
        self.source = source
        self.transformation = transformation
    }

    func apply() -> (mutatedSource: Syntax, description: String) {
        return transformation(source)
    }
}

extension MutationOperator {
    public enum Id: String, Codable, CaseIterable {
        case negateConditionals = "Negate Conditionals"
        case removeSideEffects = "Remove Side Effects"
        case logicalOperator = "Logical Operator"
        case forceFalseConditionals = "Force False Conditionals"
        
        var rewriterVisitorPair: (rewriter: RewriterInitializer, visitor: VisitorInitializer) {
            switch self {
            case .removeSideEffects:
               return (rewriter: RemoveSideEffectsOperator.Rewriter.init, visitor: RemoveSideEffectsOperator.Visitor.init)
            case .negateConditionals:
                return (rewriter: NegateConditionalsOperator.Rewriter.init, visitor: NegateConditionalsOperator.Visitor.init)
            case .logicalOperator:
                return (rewriter: LogicalOperatorOperator.Rewriter.init, visitor: LogicalOperatorOperator.Visitor.init)
            case .forceFalseConditionals:
                return (rewriter: ForceFalseConditionalOperator.Rewriter.init, visitor: ForceFalseConditionalOperator.Visitor.init)
            }
        }
        
        func transformation(for position: AbsolutePosition) -> SourceCodeTransformation {
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
