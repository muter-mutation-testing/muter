final class XcodeReporter: Reporter {
    func projectCopyFinished(destinationPath: String) {
        print("Finished copying your project to a temporary directory for mutation testing:\n\(destinationPath.bold)\n")
    }
    
    func newMutationTestOutcomeAvailable(outcomeWithFlush: MutationOutcomeWithFlush) {
        let outcome = outcomeWithFlush.mutation
        
        guard outcome.testSuiteOutcome == .passed else {
            return
        }

        print(outcomeIntoXcodeString(outcome: outcome))

        outcomeWithFlush.fflush()
    }
    
    func mutationTestingFinished(mutationTestOutcome outcome: MutationTestOutcome) {
        print(report(from: outcome))
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

        return "\(outcome.originalProjectPath):" +
            "\(outcome.point.position.line):\(outcome.point.position.column): " +
            "warning: " +
            "Your test suite did not kill this mutant: \(outcome.snapshot.description)"
    }
}
