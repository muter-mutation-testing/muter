import Foundation

/// A mutant that a `muter:disable` comment turned off. Muter does not insert it into the code or
/// test it, but the reports show it with the `ignored` outcome.
struct IgnoredMutant: Equatable, Codable {
    let point: MutationPoint
    let snapshot: MutationOperator.Snapshot
    /// Where the mutated code is. A test plan from an older Muter does not have it.
    let range: MutationRange?
    /// The source code that takes the place of the mutated code. A test plan from an older Muter
    /// does not have it.
    let replacement: String?

    init(
        point: MutationPoint,
        snapshot: MutationOperator.Snapshot,
        range: MutationRange? = nil,
        replacement: String? = nil
    ) {
        self.point = point
        self.snapshot = snapshot
        self.range = range
        self.replacement = replacement
    }
}

extension IgnoredMutant: Comparable {
    /// Source order: by file, then line, then column, then operator.
    static func < (lhs: IgnoredMutant, rhs: IgnoredMutant) -> Bool {
        (lhs.point.filePath, lhs.point.position.line, lhs.point.position.column, lhs.point.mutationOperatorId.rawValue)
            < (rhs.point.filePath, rhs.point.position.line, rhs.point.position.column, rhs.point.mutationOperatorId.rawValue)
    }
}
