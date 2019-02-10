import Foundation
import SwiftSyntax

typealias FileName = String

public struct MuterTestReport {
    let globalMutationScore: Int
    let totalAppliedMutationOperators: Int
    let fileReports: [FileReport]

    public init(from outcomes: [MutationTestOutcome] = []) {
        globalMutationScore = mutationScore(from: outcomes.map { $0.testSuiteOutcome })
        totalAppliedMutationOperators = outcomes.count
        fileReports = mutationScoreOfFiles(from: outcomes)
            .sorted(by: ascendingFilenameOrder)
            .map { mutationScoreByFilePath in
                let filePath = mutationScoreByFilePath.key
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                let mutationScore = mutationScoreByFilePath.value
                let appliedMutations = outcomes
                    .include { $0.filePath == mutationScoreByFilePath.key }
                    .map{ AppliedMutationOperator(id: $0.appliedMutation, position: $0.position, testSuiteOutcome: $0.testSuiteOutcome) }

                return (fileName, mutationScore, appliedMutations)
            }
            .map(FileReport.init(fileName:mutationScore:appliedOperators:))
    }

    struct FileReport: Codable, Equatable {
        let fileName: FileName
        let mutationScore: Int
        let appliedOperators: [AppliedMutationOperator]
    }

    struct AppliedMutationOperator: Codable, Equatable {
        let id: MutationOperator.Id
        let position: AbsolutePosition
        let testSuiteOutcome: TestSuiteOutcome
    }
}

extension MuterTestReport: Equatable {}
extension MuterTestReport: Codable {}

extension MuterTestReport: CustomStringConvertible {
    public var description: String {
        let finishedRunningMessage = "Muter finished running!\n\n"
        let appliedMutationsMessage = """
        --------------------------
        Applied Mutation Operators
        --------------------------

        These are all of the ways that Muter introduced changes into your code.

        In total, Muter applied \(totalAppliedMutationOperators) mutation operators.

        \(generateAppliedMutationsCLITable(from: self.fileReports).description)



        """

        let coloredGlobalScore = coloredMutationScore(for: self.globalMutationScore, appliedTo: "\(self.globalMutationScore)/100")
        let mutationScoreMessage = "Mutation Score of Test Suite (higher is better)".bold + ": \(coloredGlobalScore)"
        let mutationScoresMessage = """
        --------------------
        Mutation Test Scores
        --------------------

        These are the mutation scores for your test suite, as well as the files that had mutants introduced into them.

        Mutation scores ignore build & runtime errors.

        \(mutationScoreMessage)

        \(generateMutationScoresCLITable(from: self.fileReports).description)
        """

        return finishedRunningMessage + appliedMutationsMessage + mutationScoresMessage
    }

}

// MARK - Mutation Score Calculation

func mutationScore(from testResults: [TestSuiteOutcome]) -> Int {
    guard testResults.count > 0 else {
        return -1
    }

    let numberOfFailures = Double(testResults.count { $0 == .failed || $0 == .runtimeError })
    let totalResults = Double(testResults.count { $0 != .buildError })
    return Int((numberOfFailures / totalResults) * 100.0)
}

func mutationScoreOfFiles(from outcomes: [MutationTestOutcome]) -> [String: Int] {
    var mutationScores: [String: Int] = [:]

    let filePaths = outcomes.map { $0.filePath }.deduplicated()
    for filePath in filePaths {
        let testSuiteResults = outcomes.include { $0.filePath == filePath }.map { $0.testSuiteOutcome }
        mutationScores[filePath] = mutationScore(from: testSuiteResults)
    }

    return mutationScores
}

private func ascendingFilenameOrder(lhs: (String, Int), rhs: (String, Int)) -> Bool {
    return lhs.0 < rhs.0
}
