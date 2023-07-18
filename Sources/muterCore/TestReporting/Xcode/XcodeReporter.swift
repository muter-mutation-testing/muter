final class XcodeReporter: Reporter {
    @Dependency(\.logger)
    private var logger: Logger

    func newMutationTestOutcomeAvailable(outcomeWithFlush: MutationOutcomeWithFlush) {
        let outcome = outcomeWithFlush.mutation

        guard outcome.testSuiteOutcome == .passed else {
            return
        }

        logger.print(outcomeIntoXcodeString(outcome: outcome))

        outcomeWithFlush.fflush()
    }

    func report(from outcome: MutationTestOutcome) -> String {
        let report = MuterTestReport(from: outcome)
        return """
        Mutation score: \(report.globalMutationScore)
        Mutants introduced into your code: \(report.totalAppliedMutationOperators)
        Number of killed mutants: \(report.numberOfKilledMutants)
        """
    }

    private func outcomeIntoXcodeString(outcome: MutationTestOutcome.Mutation) -> String {
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}

        "\(outcome.originalProjectPath):" +
            "\(outcome.point.position.line):\(outcome.point.position.column): " +
            "warning: " +
            "Your test suite did not kill this mutant: \(outcome.snapshot.description)"
    }
}
