import Foundation
import SwiftSyntax

public struct MutationTestOutcome: Equatable {
    let testSuiteOutcome: TestSuiteOutcome
    let appliedMutation: MutationOperator.Id
    let filePath: String
    let position: AbsolutePosition

    public init(testSuiteOutcome: TestSuiteOutcome,
                appliedMutation: MutationOperator.Id,
                filePath: String,
                position: AbsolutePosition) {
        self.testSuiteOutcome = testSuiteOutcome
        self.appliedMutation = appliedMutation
        self.filePath = filePath
        self.position = position
    }
}

func performMutationTesting(using operators: [MutationOperator], delegate: MutationTestingIODelegate) -> MuterTestReport? {
    print("Running your test suite to determine a baseline for mutation testing")

    let initialResult = delegate.runTestSuite(savingResultsIntoFileNamed: "initial_run")
    guard initialResult == .passed else {
        delegate.abortTesting()
        return nil
    }

    let testOutcomes = apply(operators, delegate: delegate)
    return MuterTestReport(from: testOutcomes)
}

private func apply(_ operators: [MutationOperator], buildErrorsThreshold: Int = 5, delegate: MutationTestingIODelegate) -> [MutationTestOutcome] {
    var outcomes: [MutationTestOutcome] = []
    var buildErrors = 0

    for (index, `operator`) in operators.enumerated() {
        let filePath = `operator`.filePath
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        print("Testing mutation operator in \(fileName)")
        print("There are \(operators.count - (index + 1)) left to apply")

        delegate.backupFile(at: filePath)

        let mutatedSource = `operator`.apply()
        try! delegate.writeFile(to: filePath, contents: mutatedSource.description)

        let result = delegate.runTestSuite(savingResultsIntoFileNamed: "\(fileName)_\(`operator`.id.rawValue)_\(`operator`.position).log")
        delegate.restoreFile(at: filePath)

        outcomes.append(
            MutationTestOutcome(testSuiteOutcome: result,
                                appliedMutation: `operator`.id,
                                filePath: filePath,
                                position: `operator`.position)
        )

        buildErrors = result == .buildError ? (buildErrors + 1) : 0

        if buildErrors >= buildErrorsThreshold {
            delegate.tooManyBuildErrors()
            return []
        }
    }

    return outcomes
}

