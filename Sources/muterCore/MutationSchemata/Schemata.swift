import Foundation
import SwiftSyntax
import SwiftSyntaxParser

struct Schemata {
    let id: String
    let filePath: String
    let mutationOperatorId: MutationOperator.Id
    let syntaxMutation: CodeBlockItemListSyntax
    let positionInSourceCode: MutationPosition
    let snapshot: MutationOperatorSnapshot

    var fileName: String {
        return URL(fileURLWithPath: filePath).lastPathComponent
    }
    
    func updatingPosition(
        _ mutationPosition: MutationPosition
    ) -> Schemata {
        Schemata(
            id: id,
            filePath: filePath,
            mutationOperatorId: mutationOperatorId,
            syntaxMutation: syntaxMutation,
            positionInSourceCode: mutationPosition,
            snapshot: snapshot
        )
    }
}

extension Schemata: Nullable {
    static var null: Schemata {
        Schemata(
            id: "",
            filePath: "",
            mutationOperatorId: .ror,
            syntaxMutation: SyntaxFactory.makeBlankCodeBlockItemList(),
            positionInSourceCode: .null,
            snapshot: .null
        )
    }
}

extension Schemata: Equatable {
    static func == (lhs: Schemata, rhs: Schemata) -> Bool {
        lhs.id == rhs.id &&
        lhs.filePath == rhs.filePath &&
        lhs.mutationOperatorId == rhs.mutationOperatorId &&
        lhs.syntaxMutation.description == rhs.syntaxMutation.description &&
        lhs.positionInSourceCode == rhs.positionInSourceCode &&
        lhs.snapshot == rhs.snapshot
    }
}

extension Schemata: CustomStringConvertible, CustomDebugStringConvertible {
    var debugDescription: String { description }
    
    var description: String {
        """
        Schemata(
            id: "\(id)",
            filePath: "\(filePath)",
            mutationOperatorId: \(mutationOperatorId),
            syntaxMutation: "\(syntaxMutation.scapedDescription)",
            positionInSourceCode: \(positionInSourceCode),
            snapshot: \(snapshot)
        )
        """
    }
}

extension Schemata: Comparable {
    static func < (
        lhs: Schemata,
        rhs: Schemata
    ) -> Bool {
        lhs.id < rhs.id
    }
}
