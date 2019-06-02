
<<<<<<< HEAD
<<<<<<< HEAD
func performMutationTesting(using operators: [MutationOperator], delegate: MutationTestingIODelegate, notificationCenter: NotificationCenter = .default) -> [MutationTestOutcome] {
    let fileName = "baseline run.log"
=======
func performMutationTesting(using mutationPoints: [MutationPoint], delegate: MutationTestingIODelegate, notificationCenter: NotificationCenter = .default) -> [MutationTestOutcome] {
    let fileName = "initial_run"
>>>>>>> dd06b0c... work in progress
    let initialResult = delegate.runTestSuite(savingResultsIntoFileNamed: fileName)
    
    notificationCenter.post(name: .newTestLogAvailable, object: (nil as MutationPoint?, initialResult.testLog))
    
    guard initialResult.outcome == .passed else {
        delegate.abortTesting(reason: .initialTestingFailed)
        return []
    }

    return mutate(mutationPoints, delegate: delegate, notificationCenter: notificationCenter)
}

private func mutate(_ mutationPoints: [MutationPoint], buildErrorsThreshold: Int = 5, delegate: MutationTestingIODelegate, notificationCenter: NotificationCenter = .default) -> [MutationTestOutcome] {
    var outcomes: [MutationTestOutcome] = []
    outcomes.reserveCapacity(mutationPoints.count)

    var buildErrors = 0

    for (index, mutationPoint) in mutationPoints.enumerated() {
        let filePath = mutationPoint.filePath
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent

        delegate.backupFile(at: filePath)
        
        let mutationOperator = mutationPoint.mutationOperatorId.mutationOperator(for: mutationPoint.position)
//        let (mutatedSource, description) = mutationOperator(source)
        try! delegate.writeFile(to: filePath, contents: "".description)

        let (result, log) = delegate.runTestSuite(savingResultsIntoFileNamed: "\(fileName)_\(mutationPoint.mutationOperatorId.rawValue)_\(mutationPoint.position).log")
        delegate.restoreFile(at: filePath)

        notificationCenter.post(name: .newTestLogAvailable, object: (`operator`.mutationPoint, log))

        let outcome = MutationTestOutcome(testSuiteOutcome: result,
                                          mutationPoint: mutationPoint,
                                          operatorDescription: "")

        outcomes.append(outcome)
        
        notificationCenter.post(name: .newMutationTestOutcomeAvailable, object: (
            outcome: outcome,
            remainingOperatorsCount: mutationPoints.count - (index + 1))
        )

        buildErrors = result == .buildError ? (buildErrors + 1) : 0

        if buildErrors >= buildErrorsThreshold {
            delegate.abortTesting(reason: .tooManyBuildErrors)
            return []
        }
    }

    return outcomes
}
=======
>>>>>>> 6a0f12b... more work in progress

