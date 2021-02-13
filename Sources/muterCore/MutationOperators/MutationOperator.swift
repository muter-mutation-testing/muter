import SwiftSyntax
import Foundation

typealias SourceCodeTransformation = (SourceFileSyntax) -> (mutatedSource: SyntaxProtocol, mutationSnapshot: MutationOperatorSnapshot)
typealias RewriterInitializer = (MutationPosition) -> PositionSpecificRewriter
typealias VisitorInitializer = (MuterConfiguration, SourceFileInfo) -> PositionDiscoveringVisitor

public struct MutationPoint: Equatable, Codable {
    let mutationOperatorId: MutationOperator.Id
    let filePath: String
    let position: MutationPosition
    
    var fileName: String {
        return URL(fileURLWithPath: self.filePath).lastPathComponent
    }
    
    var mutationOperator: SourceCodeTransformation {
        return mutationOperatorId.mutationOperator(for: position)
    }
}

extension MutationPoint: Nullable {
    static var null: MutationPoint {
        MutationPoint(
            mutationOperatorId: .removeSideEffects,
            filePath: "",
            position: .null
        )
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
        
        func mutationOperator(for position: MutationPosition) -> SourceCodeTransformation {
            return { source in
                let visitor = self.rewriterVisitorPair.rewriter(position)
                let mutatedSource = visitor.visit(source)
                let operatorSnapshot = visitor.operatorSnapshot
                return (
                    mutatedSource: mutatedSource,
                    mutationSnapshot: operatorSnapshot
                )
            }
        }
    }
}

protocol PositionSpecificRewriter {
    var positionToMutate: MutationPosition { get }
    var operatorSnapshot: MutationOperatorSnapshot { get set }

    init(positionToMutate: MutationPosition)
    
    func visit(_ node: SourceFileSyntax) -> Syntax
}

protocol PositionDiscoveringVisitor {
    var positionsOfToken: [MutationPosition] { get }
    init(configuration: MuterConfiguration?, sourceFileInfo: SourceFileInfo)

    func walk<SyntaxType: SyntaxProtocol>(_ node: SyntaxType)
}
