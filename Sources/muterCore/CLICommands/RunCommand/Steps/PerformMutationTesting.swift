import Foundation

@available(OSX 10.13, *)
struct PerformMutationTesting: RunCommandStep {
    private let ioDelegate: MutationTestingIODelegate
    private let notificationCenter: NotificationCenter
    private let buildErrorsThreshold: Int = 5
    private let fileManager = FileManager.default
    
    init(ioDelegate: MutationTestingIODelegate = MutationTestingDelegate(),
         notificationCenter: NotificationCenter = .default) {
        self.ioDelegate = ioDelegate
        self.notificationCenter = notificationCenter
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        fileManager.changeCurrentDirectoryPath(state.tempDirectoryURL.path)

        let result = performMutationTesting(using: state)
        switch result {
        case .success(let outcomes):
            notificationCenter.post(name: .mutationTestingFinished, object: outcomes)
            return .success([.mutationTestOutcomesGenerated(outcomes)])
        case .failure(let reason):
            return .failure(reason)
        }
    }
}

@available(OSX 10.13, *)
private extension PerformMutationTesting {
    func performMutationTesting(using state: AnyRunCommandState) -> Result<[MutationTestOutcome], MuterError> {
        let initialResult = ioDelegate.runTestSuite(using: state.muterConfiguration,
                                                    savingResultsIntoFileNamed: "baseline run")
        
        notificationCenter.post(name: .mutationTestingStarted, object: nil)
        notificationCenter.post(name: .newTestLogAvailable, object: (MutationPoint?.none, initialResult.testLog))
        
        guard initialResult.outcome == .passed else {
            ioDelegate.abortTesting(reason: .baselineTestFailed)
            return .failure(.mutationTestingAborted(reason: .baselineTestFailed))
        }
        
        return insertMutants(using: state)
    }
    
    func insertMutants(using state: AnyRunCommandState) -> Result<[MutationTestOutcome], MuterError> {
        var outcomes: [MutationTestOutcome] = []
        outcomes.reserveCapacity(state.mutationPoints.count)
        var buildErrors = 0
        
        for (index, mutationPoint) in state.mutationPoints.enumerated() {
            let filePath = mutationPoint.filePath
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            
            ioDelegate.backupFile(at: filePath, using: state.swapFilePathsByOriginalPath)
            
            let mutationOperator = mutationPoint.mutationOperatorId.mutationOperator(for: mutationPoint.position)
            let sourceCode = state.sourceCodeByFilePath[mutationPoint.filePath]!
            
            let (mutatedSource, description) = mutationOperator(sourceCode)
            try! ioDelegate.writeFile(to: filePath, contents: mutatedSource.description)
            
            let logFileName = "\(fileName)_\(mutationPoint.mutationOperatorId.rawValue)_\(mutationPoint.position).log"
            let (result, log) = ioDelegate.runTestSuite(using: state.muterConfiguration,
                                                        savingResultsIntoFileNamed: logFileName)
            ioDelegate.restoreFile(at: filePath, using: state.swapFilePathsByOriginalPath)
            
            notificationCenter.post(name: .newTestLogAvailable, object: (mutationPoint, log))
            
            let outcome = MutationTestOutcome(testSuiteOutcome: result,
                                              mutationPoint: mutationPoint,
                                              operatorDescription: description)
            
            outcomes.append(outcome)
            
            notificationCenter.post(name: .newMutationTestOutcomeAvailable, object: (
                    outcome: outcome,
                    remainingOperatorsCount: state.mutationPoints.count - (index + 1)
                )
            )
            
            buildErrors = result == .buildError ? (buildErrors + 1) : 0
            
            if buildErrors >= buildErrorsThreshold {
                ioDelegate.abortTesting(reason: .tooManyBuildErrors)
                return .failure(.mutationTestingAborted(reason: .tooManyBuildErrors))
            }
        }
        
        return .success(outcomes)
    }
}
