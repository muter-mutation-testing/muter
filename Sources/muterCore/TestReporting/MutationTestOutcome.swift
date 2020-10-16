import Foundation

public struct MutationTestOutcome: Equatable {
    let testSuiteOutcome: TestSuiteOutcome
    let mutationPoint: MutationPoint
    let mutationSnapshot: MutationOperatorSnapshot
    let originalProjectPath: String
    
    public init(testSuiteOutcome: TestSuiteOutcome,
                mutationPoint: MutationPoint,
                mutationSnapshot: MutationOperatorSnapshot,
                originalProjectDirectoryUrl: URL) {
        self.testSuiteOutcome = testSuiteOutcome
        self.mutationPoint = mutationPoint
        self.mutationSnapshot = mutationSnapshot
        
        let splitTempFilePath = mutationPoint.filePath.split(separator: "/")
        let projectDirectoryName = originalProjectDirectoryUrl.lastPathComponent
        let numberOfDirectoriesToDrop = splitTempFilePath.map(String.init).firstIndex(of: projectDirectoryName) ?? 0
        let pathSuffix = splitTempFilePath.dropFirst(numberOfDirectoriesToDrop).joined(separator: "/")
        
        self.originalProjectPath = originalProjectDirectoryUrl
            .deletingLastPathComponent()
            .appendingPathComponent(pathSuffix, isDirectory: true)
            .path
    }
}
