import Foundation

final class PlainTextReporter: Reporter {    
    func report(from outcome: MutationTestOutcome) -> String {
        let report = MuterTestReport(from: outcome)
        let finishedRunningMessage = "\n\nHere's your test report:\n\n"
        let appliedMutationsMessage = """
        --------------------------
        Applied Mutation Operators
        --------------------------
        
        These are all of the ways that Muter introduced changes into your code.
        
        In total, Muter introduced \(report.totalAppliedMutationOperators) mutants in \(report.fileReports.count) files.
        
        \(generateAppliedMutationOperatorsCLITable(from: report.fileReports).description)
        
        
        """
        
        let coloredGlobalScore = coloredMutationScore(for: report.globalMutationScore, appliedTo: "\(report.globalMutationScore)%")
        let projectCoverageMessage = coverageMessage(from: report)
        let mutationScoreMessage = "Mutation Score of Test Suite: ".bold + "\(coloredGlobalScore)"
        let mutationScoresMessage = """
        --------------------
        Mutation Test Scores
        --------------------
        
        These are the mutation scores for your test suite, as well as the files that had mutants introduced into them.
        
        Mutation scores ignore build errors.
        
        Of the \(report.totalAppliedMutationOperators) mutants introduced into your code, your test suite killed \(report.numberOfKilledMutants).
        \(mutationScoreMessage)
        \(projectCoverageMessage)
        
        \(generateMutationScoresCLITable(from: report.fileReports).description)
        """
        
        return finishedRunningMessage + appliedMutationsMessage + mutationScoresMessage
    }
    
    private func coverageMessage(from report: MuterTestReport) -> String {
        report.projectCodeCoverage.map { "Code Coverage of your project: \($0)%" }
            ?? "Muter could not gather coverage data from your project"
    }
}
