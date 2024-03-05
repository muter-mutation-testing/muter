import Foundation
import SwiftParser
import SwiftSyntax

struct MutationSchema {
    var id: String {
        let fileName = URL(fileURLWithPath: filePath)
            .deletingPathExtension()
            .lastPathComponent

        return "\(fileName)_\(mutationOperatorId.rawValue)_\(position.line)_\(position.column)_\(position.utf8Offset)"
    }

    let filePath: String
    let mutationOperatorId: MutationOperator.Id
    let syntaxMutation: CodeBlockItemListSyntax
    let position: MutationPosition
    let snapshot: MutationOperator.Snapshot

    var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }
}

extension MutationSchema: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        filePath = try container.decode(String.self, forKey: .filePath)
        mutationOperatorId = try container.decode(MutationOperator.Id.self, forKey: .mutationOperatorId)
        syntaxMutation = CodeBlockItemListSyntax([])
        position = try container.decode(MutationPosition.self, forKey: .position)
        snapshot = try container.decode(MutationOperator.Snapshot.self, forKey: .snapshot)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(filePath, forKey: .filePath)
        try container.encode(mutationOperatorId, forKey: .mutationOperatorId)
        try container.encode(position, forKey: .position)
        try container.encode(snapshot, forKey: .snapshot)
    }

    enum CodingKeys: String, CodingKey {
        case filePath
        case mutationOperatorId
        case position
        case snapshot
    }
}

extension MutationSchema: Nullable {
    static var null: MutationSchema {
        MutationSchema(
            filePath: "",
            mutationOperatorId: .ror,
            syntaxMutation: CodeBlockItemListSyntax([]),
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
            mutationOperatorId: .\(mutationOperatorId),
            syntaxMutation: "\(syntaxMutation.escapedDescription)",
            position: \(position.debugDescription),
            snapshot: \(snapshot.debugDescription)
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
        URL(fileURLWithPath: filePath).lastPathComponent
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
