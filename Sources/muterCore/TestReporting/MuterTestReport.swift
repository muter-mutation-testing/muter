import Foundation
import SwiftSyntax

typealias FileName = String

public struct MuterTestReport {
    let globalMutationScore: Int
    let totalAppliedMutationOperators: Int
    let fileReports: [FileReport]
    let numberOfKilledMutants: Int

    public init(from outcomes: [MutationTestOutcome] = []) {
        globalMutationScore = mutationScore(from: outcomes.map { $0.testSuiteOutcome })
        totalAppliedMutationOperators = outcomes.count
        fileReports = mutationScoreOfFiles(from: outcomes)
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
        
        numberOfKilledMutants = outcomes.map{ $0.testSuiteOutcome }.count { $0 == .failed || $0 == .runtimeError }
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

        let coloredGlobalScore = coloredMutationScore(for: self.globalMutationScore, appliedTo: "\(self.globalMutationScore)%")
        let mutationScoreMessage = "giving your test suite a mutation score of ".bold + "\(coloredGlobalScore)"
        let mutationScoresMessage = """
        --------------------
        Mutation Test Scores
        --------------------

        These are the mutation scores for your test suite, as well as the files that had mutants introduced into them.

        Mutation scores ignore build errors.
        
        Of the \(self.totalAppliedMutationOperators) mutants introduced into your code, your test suite killed \(self.numberOfKilledMutants),
        \(mutationScoreMessage)

        \(generateMutationScoresCLITable(from: self.fileReports).description)
        """

        return finishedRunningMessage + appliedMutationsMessage + mutationScoresMessage
    }
}
