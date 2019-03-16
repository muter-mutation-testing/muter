import Foundation

typealias Reporter = (MuterTestReport) -> String

public func jsonReporter(report: MuterTestReport) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    guard let encoded = try? encoder.encode(report),
        let json = String(data: encoded, encoding: .utf8) else {
            return ""
    }

    return json
}

public func xcodeReporter(report: MuterTestReport) -> String {
    // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
    return report.fileReports.map { (file: MuterTestReport.FileReport) -> String in
        let path = file.path
        return file.appliedOperators
            .filter { $0.testSuiteOutcome == .passed }
            .map {
                "\(path):" +
                    "\($0.position.line):\($0.position.column): " +
                    "warning: " +
                "\"Your test suite did not kill this mutant: \($0.id.rawValue.lowercased())\""
            }.joined(separator: "\n")
        }.joined(separator: "\n")
}

public func textReporter(report: MuterTestReport) -> String {
    let finishedRunningMessage = "Muter finished running!\n\n"
    let appliedMutationsMessage = """
    --------------------------
    Applied Mutation Operators
    --------------------------
    
    These are all of the ways that Muter introduced changes into your code.
    
    In total, Muter applied \(report.totalAppliedMutationOperators) mutation operators.
    
    \(generateAppliedMutationsCLITable(from: report.fileReports).description)
    
    
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
