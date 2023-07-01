import Foundation
import SwiftSyntax

struct PerformMutationTesting: RunCommandStep {
    @Dependency(\.ioDelegate)
    private var ioDelegate: MutationTestingIODelegate
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager

    private let buildErrorsThreshold: Int = 5

    func run(
        with state: AnyRunCommandState
    ) -> Result<[RunCommandState.Change], MuterError> {

        fileManager.changeCurrentDirectoryPath(state.tempDirectoryURL.path)

        let result = performMutationTesting(using: state)
        switch result {
        case let .success(outcomes):
            let mutationTestOutcome = state.mutationTestOutcome
            mutationTestOutcome.mutations = outcomes
            mutationTestOutcome.coverage = state.projectCoverage

            notificationCenter.post(
                name: .mutationTestingFinished,
                object: mutationTestOutcome
            )

            return .success([
                .mutationTestOutcomeGenerated(mutationTestOutcome)
            ])
        case let .failure(reason):
            return .failure(reason)
        }
    }
}

private extension PerformMutationTesting {
    func performMutationTesting(
        using state: AnyRunCommandState
    ) -> Result<[MutationTestOutcome.Mutation], MuterError> {
        notificationCenter.post(name: .mutationTestingStarted, object: nil)

        let initialTime = Date()
        let (testSuiteOutcome, testLog) = ioDelegate.runTestSuite(
            withSchemata: .null,
            using: state.muterConfiguration,
            savingResultsIntoFileNamed: "baseline run"
        )

        let timeAfterRunningTestSuite = Date()
        let timePerBuildTestCycle = DateInterval(
            start: initialTime,
            end: timeAfterRunningTestSuite
        ).duration

        guard testSuiteOutcome == .passed else {
            return .failure(
                .mutationTestingAborted(
                    reason: .baselineTestFailed(log: testLog)
                )
            )
        }

        let mutationLog = MutationTestLog(
            mutationPoint: .none,
            testLog: testLog,
            timePerBuildTestCycle: timePerBuildTestCycle,
            remainingMutationPointsCount: state.mutationPoints.count
        )

        notificationCenter.post(
            name: .newTestLogAvailable,
            object: mutationLog
        )

        return insertMutants(using: state)
    }

    func insertMutants(
        using state: AnyRunCommandState
    ) -> Result<[MutationTestOutcome.Mutation], MuterError> {
        var outcomes: [MutationTestOutcome.Mutation] = []
        outcomes.reserveCapacity(state.mutationPoints.count)
        var buildErrors = 0

        for mutationMap in state.mutationMapping {
            for mutationSchema in mutationMap.mutationSchemata {

                try! ioDelegate.switchOn(
                    schemata: mutationSchema,
                    for: state.projectXCTestRun,
                    at: state.tempDirectoryURL
                )

                let (testSuiteOutcome, testLog) = ioDelegate.runTestSuite(
                    withSchemata: mutationSchema,
                    using: state.muterConfiguration,
                    savingResultsIntoFileNamed: logFileName(
                        for: mutationMap.fileName,
                        schemata: mutationSchema
                    )
                )

                let mutationPoint = MutationPoint(
                    mutationOperatorId: mutationSchema.mutationOperatorId,
                    filePath: mutationSchema.filePath,
                    position: mutationSchema.position
                )

                let outcome = MutationTestOutcome.Mutation(
                    testSuiteOutcome: testSuiteOutcome,
                    mutationPoint: mutationPoint,
                    mutationSnapshot: mutationSchema.snapshot,
                    originalProjectDirectoryUrl: state.projectDirectoryURL,
                    tempDirectoryURL: state.tempDirectoryURL
                )

                outcomes.append(outcome)

                let mutationLog = MutationTestLog(
                    mutationPoint: mutationPoint,
                    testLog: testLog,
                    timePerBuildTestCycle: .none,
                    remainingMutationPointsCount: .none
                )

                notificationCenter.post(
                    name: .newMutationTestOutcomeAvailable,
                    object: outcome
                )

                notificationCenter.post(
                    name: .newTestLogAvailable,
                    object: mutationLog
                )

                buildErrors = testSuiteOutcome == .buildError ? (buildErrors + 1) : 0
                if buildErrors >= buildErrorsThreshold {
                    return .failure(.mutationTestingAborted(reason: .tooManyBuildErrors))
                }
            }
        }

        return .success(outcomes)
    }

    func logFileName(
        for fileName: FileName,
        schemata: MutationSchema
    ) -> String {
        "\(fileName)_\(schemata.mutationOperatorId.rawValue)_\(schemata.position).log"
    }
}
