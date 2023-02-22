import Foundation
import SwiftSyntax
import SwiftSyntaxParser

struct MutationSchema {
    var id: String {
        let fileName = URL(fileURLWithPath: filePath)
            .deletingPathExtension()
            .lastPathComponent

        return "\(fileName)_\(position.line)_\(position.column)_\(position.utf8Offset)"
    }

    let filePath: String
    let mutationOperatorId: MutationOperator.Id
    let syntaxMutation: CodeBlockItemListSyntax
    let position: MutationPosition
    let snapshot: MutationOperator.Snapshot

    var fileName: String {
        return URL(fileURLWithPath: filePath).lastPathComponent
    }
}

extension MutationSchema: Nullable {
    static var null: MutationSchema {
        MutationSchema(
            filePath: "",
            mutationOperatorId: .ror,
            syntaxMutation: SyntaxFactory.makeBlankCodeBlockItemList(),
            position: .null,
            snapshot: .null
        )
    }
}

extension MutationSchema: Equatable {
    static func == (lhs: MutationSchema, rhs: MutationSchema) -> Bool {
        lhs.id == rhs.id &&
        lhs.filePath == rhs.filePath &&
        lhs.mutationOperatorId == rhs.mutationOperatorId &&
        lhs.syntaxMutation.description == rhs.syntaxMutation.description &&
        lhs.position == rhs.position &&
        lhs.snapshot == rhs.snapshot
    }
}

extension MutationSchema: CustomStringConvertible, CustomDebugStringConvertible {
    var debugDescription: String { description }
    
    var description: String {
        """
        Schemata(
            id: "\(id)",
            filePath: "\(filePath)",
            mutationOperatorId: \(mutationOperatorId),
            syntaxMutation: "\(syntaxMutation.scapedDescription)",
            position: \(position),
            snapshot: \(snapshot)
        )
        """
    }
}

extension MutationSchema: Comparable {
    static func < (
        lhs: MutationSchema,
        rhs: MutationSchema
    ) -> Bool {
        lhs.id < rhs.id
    }
}

struct MutationPoint: Equatable, Codable {
    let mutationOperatorId: MutationOperator.Id
    let filePath: String
    let position: MutationPosition
    
    var fileName: String {
        return URL(fileURLWithPath: self.filePath).lastPathComponent
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
