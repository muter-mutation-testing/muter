import Foundation

struct MutationTestOutcome {
    let mutations: [Mutation]
    let coverage: Coverage
    let testDuration: TimeInterval
    let newVersion: String

    init(
        mutations: [Mutation] = [],
        coverage: Coverage = .null,
        testDuration: TimeInterval = 0,
        newVersion: String = ""
    ) {
        self.mutations = mutations
        self.coverage = coverage
        self.testDuration = testDuration
        self.newVersion = newVersion
    }
}

extension MutationTestOutcome: Equatable {}

extension MutationTestOutcome {
    struct Mutation: Equatable {
        let testSuiteOutcome: TestSuiteOutcome
        let point: MutationPoint
        let snapshot: MutationOperator.Snapshot
        let originalProjectPath: String
        /// The path of the file in the project, from the project's root directory.
        let relativePath: String
        /// How many tests failed with this mutant, or `nil` when the test log does not say.
        let failedTests: Int?
        /// Where the mutated code is, or `nil` for a mutant from an older test plan.
        let range: MutationRange?

        init(
            testSuiteOutcome: TestSuiteOutcome,
            mutationPoint: MutationPoint,
            mutationSnapshot: MutationOperator.Snapshot,
            originalProjectDirectoryUrl: URL,
            mutatedProjectDirectoryURL: URL,
            failedTests: Int? = nil,
            range: MutationRange? = nil
        ) {
            self.testSuiteOutcome = testSuiteOutcome
            self.failedTests = failedTests
            self.range = range
            point = mutationPoint
            snapshot = mutationSnapshot

            let splitTempFilePath = mutationPoint.filePath.split(separator: "/")
            let tempProjectDirectoryName = mutatedProjectDirectoryURL.lastPathComponent
            let numberOfDirectoriesToDrop = splitTempFilePath.map(String.init)
                .firstIndex(of: tempProjectDirectoryName) ?? 0
            let pathSuffix = splitTempFilePath.dropFirst(numberOfDirectoriesToDrop + 1).joined(separator: "/")
            relativePath = pathSuffix

            originalProjectPath = originalProjectDirectoryUrl
                .appendingPathComponent(pathSuffix, isDirectory: true)
                .path
        }
    }
}
