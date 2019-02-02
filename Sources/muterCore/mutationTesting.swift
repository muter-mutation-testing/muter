import Foundation
import SwiftSyntax

struct MutationTestOutcome: Equatable {
    let testSuiteResult: TestSuiteResult
    let appliedMutation: String
    let filePath: String
    let position: AbsolutePosition
}

func performMutationTesting(using operators: [MutationOperator], buildErrorsThreshold: Int = 5, delegate: MutationTestingIODelegate) -> [MutationTestOutcome] {
    print("Running your test suite to determine a baseline for mutation testing")
    
    let initialResult = delegate.runTestSuite(savingResultsIntoFileNamed: "initial_run")
    guard initialResult == .passed else {
        delegate.abortTesting()
        return nil
    }
    
    let testOutcomes = apply(operators, delegate: delegate)
    return MuterTestReport(from: testOutcomes)
}

private func apply(_ operators: [MutationOperator], delegate: MutationTestingIODelegate) -> [MutationTestOutcome] {
    var outcomes: [MutationTestOutcome] = []
    var buildErrors = 0
    
    return operators.enumerated().map { index, `operator` in
        
        let filePath = `operator`.filePath
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        print("Testing mutation operator in \(fileName)")
        print("There are \(operators.count - (index + 1)) left to apply")
        
        delegate.backupFile(at: filePath)
        
        let mutatedSource = `operator`.apply()
        try! delegate.writeFile(to: filePath, contents: mutatedSource.description)
        delegate.restoreFile(at: filePath)

        outcomes.append(
            MutationTestOutcome(testSuiteResult: result,
                                appliedMutation: `operator`.id.rawValue,
                                filePath: filePath,
                                position: `operator`.position)
        )

        buildErrors = result == .buildError ? (buildErrors + 1) : 0

        if buildErrors >= buildErrorsThreshold {
            delegate.tooManyBuildErrors()
            return []
        }
        
        return MutationTestOutcome(testSuiteResult: result,
                                   appliedMutation: `operator`.id.rawValue,
                                   filePath: filePath,
                                   position: `operator`.position)
    }
}

