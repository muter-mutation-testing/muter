import Foundation
import SwiftSyntax

func performMutationTesting(using operators: [MutationOperator], delegate: MutationTestingIODelegate) -> [MutationTestOutcome] {

    let initialResult = delegate.runTestSuite(savingResultsIntoFileNamed: "initial_run")
    guard initialResult.outcome == .passed else {
        delegate.abortTesting(reason: .initialTestingFailed)
        return []
    }

    return apply(operators, delegate: delegate)
}

private func apply(_ operators: [MutationOperator], buildErrorsThreshold: Int = 5, delegate: MutationTestingIODelegate, notificationCenter: NotificationCenter = .default) -> [MutationTestOutcome] {
    var outcomes: [MutationTestOutcome] = []
    outcomes.reserveCapacity(operators.count)

    var buildErrors = 0

    for (index, `operator`) in operators.enumerated() {
        let filePath = `operator`.mutationPoint.filePath
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent

        delegate.backupFile(at: filePath)
        
        let sourceOperator = `operator`.mutationPoint.mutationOperatorId.transformation(for: `operator`.mutationPoint.position)
        let (mutatedSource, description) = sourceOperator(`operator`.source)
        try! delegate.writeFile(to: filePath, contents: mutatedSource.description)

        let (result, log) = delegate.runTestSuite(savingResultsIntoFileNamed: "\(fileName)_\(`operator`.mutationPoint.mutationOperatorId.rawValue)_\(`operator`.mutationPoint.position).log")
        delegate.restoreFile(at: filePath)

        notificationCenter.post(name: .newTestLogAvailable, object: (fileName, log))

        let outcome = MutationTestOutcome(testSuiteOutcome: result,
                                          mutationPoint: `operator`.mutationPoint,
                                          operatorDescription: description)

        outcomes.append(outcome)
        
        notificationCenter.post(name: .newMutationTestOutcomeAvailable, object: (
            outcome: outcome,
            remainingOperatorsCount: operators.count - (index + 1))
        )

        buildErrors = result == .buildError ? (buildErrors + 1) : 0

        if buildErrors >= buildErrorsThreshold {
            delegate.abortTesting(reason: .tooManyBuildErrors)
            return []
        }
    }

    return outcomes
}

