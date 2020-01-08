import SwiftSyntax
import Foundation

typealias SourceCodeTransformation = (Syntax) -> (mutatedSource: Syntax, description: String)
typealias RewriterInitializer = (AbsolutePosition) -> PositionSpecificRewriter
typealias VisitorInitializer = (MuterConfiguration) -> PositionDiscoveringVisitor

public struct MutationPoint: Equatable, Codable {
    let mutationOperatorId: MutationOperator.Id
    let filePath: String
    let position: AbsolutePosition
    
    var fileName: String {
        return URL(fileURLWithPath: self.filePath).lastPathComponent
    }
    
    var mutationOperator: SourceCodeTransformation {
        return mutationOperatorId.mutationOperator(for: position)
    }
}

struct MutationOperator {
    public enum Id: String, Codable, CaseIterable {
        case ror = "RelationalOperatorReplacement"
        case removeSideEffects = "RemoveSideEffects"
        case logicalOperator = "ChangeLogicalConnector"
        
        var rewriterVisitorPair: (rewriter: RewriterInitializer, visitor: VisitorInitializer) {
            switch self {
            case .removeSideEffects:
               return (rewriter: RemoveSideEffectsOperator.Rewriter.init,
                       visitor: RemoveSideEffectsOperator.Visitor.init)
            case .ror:
                return (rewriter: ROROperator.Rewriter.init,
                        visitor: ROROperator.Visitor.init)
            case .logicalOperator:
                return (rewriter: ChangeLogicalConnectorOperator.Rewriter.init,
                        visitor: ChangeLogicalConnectorOperator.Visitor.init)
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
