import Foundation
import SwiftSyntax

typealias VisitorInitializer = (MuterConfiguration?, SourceCodeInfo, [Region]) -> MuterVisitor
typealias MutationOperatorList = [MutationOperator.Id]

extension [MutationOperator.Id] {
    static var allOperators = MutationOperator.Id.allCases
}

enum MutationOperator {
    enum Id: String, Codable, CaseIterable {
        case ror = "RelationalOperatorReplacement"
        case removeSideEffects = "RemoveSideEffects"
        case logicalOperator = "ChangeLogicalConnector"
        case swapTernary = "SwapTernary"

        var visitor: VisitorInitializer {
            switch self {
            case .removeSideEffects:
                return RemoveSideEffectsOperator.Visitor.init
            case .ror:
                return ROROperator.Visitor.init
            case .logicalOperator:
                return ChangeLogicalConnectorOperator.Visitor.init
            case .swapTernary:
                return SwapTernaryOperator.Visitor.init
            }
        }

        static var description: String {
            allCases.map(\.rawValue).joined(separator: ", ")
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

extension MutationOperator.Snapshot: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        MutationOperator.Snapshot(
            before: "\(before)",
            after: "\(after)",
            description: "\(description)"
        )
        """
    }
}
