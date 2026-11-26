import Foundation
import SwiftParser
import SwiftSyntax

struct MutationSchema {
    /// The number that switches this mutant on, unique in the whole run. Discovery numbers the
    /// mutants from 1 (see `numberedMutants()`), and a mutated file checks
    /// `__SwiftMutator.activeMutant == id`.
    var id: Int

    /// The operator and position of the mutant in its file. It orders the mutants of a file, but it
    /// is not unique in the run: two files can have the same name.
    var positionKey: String {
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

    init(
        id: Int = 0,
        filePath: String,
        mutationOperatorId: MutationOperator.Id,
        syntaxMutation: CodeBlockItemListSyntax,
        position: MutationPosition,
        snapshot: MutationOperator.Snapshot
    ) {
        self.id = id
        self.filePath = filePath
        self.mutationOperatorId = mutationOperatorId
        self.syntaxMutation = syntaxMutation
        self.position = position
        self.snapshot = snapshot
    }

    var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }
}

extension MutationSchema: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        filePath = try container.decode(String.self, forKey: .filePath)
        mutationOperatorId = try container.decode(MutationOperator.Id.self, forKey: .mutationOperatorId)
        syntaxMutation = CodeBlockItemListSyntax([])
        position = try container.decode(MutationPosition.self, forKey: .position)
        snapshot = try container.decode(MutationOperator.Snapshot.self, forKey: .snapshot)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(filePath, forKey: .filePath)
        try container.encode(mutationOperatorId, forKey: .mutationOperatorId)
        try container.encode(position, forKey: .position)
        try container.encode(snapshot, forKey: .snapshot)
    }

    enum CodingKeys: String, CodingKey {
        case id
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
            id: \(id),
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
        (lhs.filePath, lhs.positionKey) < (rhs.filePath, rhs.positionKey)
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
