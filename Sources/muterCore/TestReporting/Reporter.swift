import Foundation

enum Reporter: Equatable {
    case plainText
    case json
    case xcode
    
    func generateReport(from outcomes: [MutationTestOutcome], footerOnly: Bool = false) -> String {
        switch self {
        case .plainText:
            return textReport(from: outcomes)
        case .json:
            return jsonReport(from: outcomes)
        case .xcode:
            return xcodeReport(from: outcomes, footerOnly: footerOnly)
        }
    }
}

extension Reporter {
    init(shouldOutputJson: Bool, shouldOutputXcode: Bool) {
        if shouldOutputJson {
            self = .json
        }
        else if shouldOutputXcode {
            self = .xcode
        }
        else {
            self = .plainText
        }
    }
}

private extension Reporter {
    func textReport(from outcomes: [MutationTestOutcome]) -> String {
        let report = MuterTestReport(from: outcomes)
        
        let finishedRunningMessage = "Muter finished running!\n\nHere's your test report:\n\n"
        let appliedMutationsMessage = """
        --------------------------
        Applied Mutation Operators
        --------------------------
        
        These are all of the ways that Muter introduced changes into your code.
        
        In total, Muter introduced \(report.totalAppliedMutationOperators) mutants in \(report.fileReports.count) files.
        
        \(generateAppliedMutationOperatorsCLITable(from: report.fileReports).description)
        
        
        """
        
        let coloredGlobalScore = coloredMutationScore(for: report.globalMutationScore, appliedTo: "\(report.globalMutationScore)%")
        let mutationScoreMessage = "Mutation Score of Test Suite: ".bold + "\(coloredGlobalScore)"
        let mutationScoresMessage = """
        --------------------
        Mutation Test Scores
        --------------------
        
        These are the mutation scores for your test suite, as well as the files that had mutants introduced into them.
        
        Mutation scores ignore build errors.
        
        Of the \(report.totalAppliedMutationOperators) mutants introduced into your code, your test suite killed \(report.numberOfKilledMutants).
        \(mutationScoreMessage)
        
        \(generateMutationScoresCLITable(from: report.fileReports).description)
        """
        
        return finishedRunningMessage + appliedMutationsMessage + mutationScoresMessage
    }
    


}
