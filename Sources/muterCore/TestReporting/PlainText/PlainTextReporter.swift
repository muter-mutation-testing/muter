import Foundation

final class PlainTextReporter: Reporter {
    func report(from outcome: MutationTestOutcome) -> String {
        let report = MuterTestReport(from: outcome)
        let appliedMutationsMessage = """
        --------------------------
        Applied Mutation Operators
        --------------------------

        These are all of the ways that Muter introduced changes into your code.

        In total, Muter introduced \(report.totalAppliedMutationOperators) mutants in \(report.fileReports.count) files.

        \(generateAppliedMutationOperatorsCLITable(from: report.fileReports).description)


        """

        let coloredGlobalScore = coloredMutationScore(
            for: report.globalMutationScore,
            appliedTo: "\(report.globalMutationScore)%"
        )
        let projectCoverageMessage = coverageMessage(from: report)
        let mutationScoreMessage = "Mutation Score of Test Suite: ".bold + "\(coloredGlobalScore)"
        let mutationScoresMessage = """
        --------------------
        Mutation Test Scores
        --------------------

        Muter took \(report.timeElapsed) to run.

        These are the mutation scores for your test suite, as well as the files that had mutants introduced into them.

        Mutation scores ignore build errors.

        Of the \(
            report.totalAppliedMutationOperators
        ) mutants introduced into your code, your test suite killed \(
            report.numberOfKilledMutants
        ).
        \(mutationScoreMessage)
        \(projectCoverageMessage)

        \(generateMutationScoresCLITable(from: report.fileReports).description)
        """

        return appliedMutationsMessage + mutationScoresMessage + testFailuresMessage(from: report)
    }

    private func testFailuresMessage(from report: MuterTestReport) -> String {
        let average = report.averageNumberOfFailedTests
            .map { "On average, each mutant made \(formatted($0)) tests fail." }
            ?? "No test run reported how many tests failed."

        return """


        ----------------------------------
        Test Failures by Mutation Operator
        ----------------------------------

        These are the tests that failed because of each mutation operator's mutants.
        Runs that did not report a count, such as build errors and timeouts, are left out.

        \(average)

        \(generateTestFailuresCLITable(from: report.operatorReports).description)
        """
    }

    private func coverageMessage(from report: MuterTestReport) -> String {
        report.projectCodeCoverage.map { "Code Coverage of your project: \($0)%" }
            ?? "Muter could not gather coverage data from your project"
    }
}

func formatted(_ average: Double) -> String {
    String(format: "%.2f", average)
}
