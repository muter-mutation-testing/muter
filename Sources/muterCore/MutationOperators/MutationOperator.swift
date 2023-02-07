import SwiftSyntax
import Foundation

typealias SourceCodeTransformation = (SourceFileSyntax) -> (mutatedSource: SyntaxProtocol, mutationSnapshot: MutationOperatorSnapshot)
typealias RewriterInitializer = (MutationPosition) -> PositionSpecificRewriter
typealias VisitorInitializer = (MuterConfiguration, SourceFileInfo) -> PositionDiscoveringVisitor

typealias SchemataVisitorInitializer = (MuterConfiguration, SourceFileInfo) -> MutationSchemataVisitor


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
        case ternaryOperator = "SwapTernaryOperator"
        
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
            case .ternaryOperator:
                return (rewriter: TernaryOperator.Rewriter.init,
                        visitor: TernaryOperator.Visitor.init)
            }
        }
        
        var schemataVisitor: SchemataVisitorInitializer {
            switch self{
            case .removeSideEffects:
                return RemoveSideEffectsOperator.SchemataVisitor.init
            case .ror:
                return ROROperator.SchemataVisitor.init
            case .logicalOperator:
                return ChangeLogicalConnectorOperator.SchemataVisitor.init
            case .ternaryOperator:
                return TernaryOperator.SchemataVisitor.init
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


//protocol MutationSchemataVisitor {
//    var schemataMappings: SchemataMutationMapping { get }
//    init(
//        configuration: MuterConfiguration?,
//        sourceFileInfo: SourceFileInfo
//    )
//
//    func walk<SyntaxType: SyntaxProtocol>(_ node: SyntaxType)
//}

class MutationSchemataVisitor: SyntaxAnyVisitor {
    var schemataMappings: SchemataMutationMapping = .init()
    let configuration: MuterConfiguration?
    let sourceFileInfo: SourceFileInfo

    required init(
        configuration: MuterConfiguration?,
        sourceFileInfo: SourceFileInfo
    ) {
        self.configuration = configuration
        self.sourceFileInfo = sourceFileInfo
    }
}
