public struct MutationOperatorSnapshot: Equatable, Codable {
    let before: String
    let after: String
    let description: String
}

public extension MutationOperatorSnapshot {
    static var null: MutationOperatorSnapshot { .init(before: "", after: "", description: "") }
}
