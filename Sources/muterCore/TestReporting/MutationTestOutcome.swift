import SwiftSyntax
import Foundation

public struct MutationTestOutcome: Equatable {
    let testSuiteOutcome: TestSuiteOutcome
    let mutationPoint: MutationPoint
    let operatorDescription: String
    let originalProjectPath: String

    public init(testSuiteOutcome: TestSuiteOutcome,
                mutationPoint: MutationPoint,
                operatorDescription: String,
                originalProjectDirectoryUrl: URL) {
        self.testSuiteOutcome = testSuiteOutcome
        self.mutationPoint = mutationPoint
        self.operatorDescription = operatorDescription

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
