import Foundation

/// A mutant that a `muter:disable` comment turned off. Muter does not insert it into the code or
/// test it, but the reports show it with the `ignored` outcome.
struct IgnoredMutant: Equatable, Codable {
    let point: MutationPoint
    let snapshot: MutationOperator.Snapshot
}

extension IgnoredMutant: Comparable {
    /// Source order: by file, then line, then column, then operator.
    static func < (lhs: IgnoredMutant, rhs: IgnoredMutant) -> Bool {
        (lhs.point.filePath, lhs.point.position.line, lhs.point.position.column, lhs.point.mutationOperatorId.rawValue)
            < (rhs.point.filePath, rhs.point.position.line, rhs.point.position.column, rhs.point.mutationOperatorId.rawValue)
    }
}
