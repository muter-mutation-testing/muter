import Foundation

struct MutationTestLog {
    let mutationPoint: _MutationPoint?
    let testLog: String
    let timePerBuildTestCycle: TimeInterval?
    let remainingMutationPointsCount: Int?
}
