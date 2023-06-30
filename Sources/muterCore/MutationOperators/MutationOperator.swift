import Foundation
import SwiftSyntax

typealias VisitorInitializer = (MuterConfiguration?, SourceFileInfo) -> MuterVisitor

enum MutationOperator {
    enum Id: String, Codable, CaseIterable {
        case ror = "RelationalOperatorReplacement"
        case removeSideEffects = "RemoveSideEffects"
        case logicalOperator = "ChangeLogicalConnector"
        case ternaryOperator = "SwapTernaryOperator"

        var visitor: VisitorInitializer {
            switch self {
            case .removeSideEffects:
                return RemoveSideEffectsOperator.Visitor.init
            case .ror:
                return ROROperator.Visitor.init
            case .logicalOperator:
                return ChangeLogicalConnectorOperator.Visitor.init
            case .ternaryOperator:
                return TernaryOperator.Visitor.init
            }
        }
    }

    struct Snapshot: Codable, Equatable {
        let before: String
        let after: String
        let description: String
    }
}

extension MutationOperator.Snapshot {
    static var null: MutationOperator.Snapshot {
        MutationOperator.Snapshot(
            before: "",
            after: "",
            description: ""
        )
    }
}
