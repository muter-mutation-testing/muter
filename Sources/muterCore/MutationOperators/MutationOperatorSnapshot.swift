struct MutationOperatorSnapshot: Codable, Equatable {
    let before: String
    let after: String
    let description: String
}

extension MutationOperatorSnapshot: Nullable {
    static var null: MutationOperatorSnapshot {
        MutationOperatorSnapshot(
            before: "",
            after: "",
            description: ""
        )
    }
}
