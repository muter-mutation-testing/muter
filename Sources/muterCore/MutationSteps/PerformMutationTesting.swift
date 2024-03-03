import Foundation
import SwiftSyntax

struct PerformMutationTesting: RunCommandStep {
    @Dependency(\.ioDelegate)
    private var ioDelegate: MutationTestingIODelegate
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.now)
    private var now: Now

    private let buildErrorsThreshold: Int = 5

    func run(
        with state: AnyRunCommandState
    ) async throws -> [RunCommandState.Change] {
        fileManager.changeCurrentDirectoryPath(state.mutatedProjectDirectoryURL.path)

        let (mutationOutcome, testDuration) = try await benchmarkMutationTesting {
            try await performMutationTesting(using: state)
        }

        let mutationTestOutcome = MutationTestOutcome(
            mutations: mutationOutcome,
            coverage: state.projectCoverage,
            testDuration: testDuration,
            newVersion: state.newVersion
        )

        notificationCenter.post(
            name: .mutationTestingFinished,
            object: mutationTestOutcome
        )

        return [.mutationTestOutcomeGenerated(mutationTestOutcome)]
    }

    private func benchmarkMutationTesting<T>(
        _ work: () async throws -> T
    ) async throws -> (result: T, duration: TimeInterval) {
        let initialTime = now()
        let result = try await work()
        let duration = DateInterval(
            start: initialTime,
            end: now()
        ).duration

        return (result, duration)
    }
}

private extension PerformMutationTesting {
    func performMutationTesting(
        using state: AnyRunCommandState
    ) async throws -> [MutationTestOutcome.Mutation] {
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
            throw MuterError.mutationTestingAborted(
                reason: .baselineTestFailed(log: testLog)
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

        return try await testMutation(using: state)
    }

    func testMutation(using state: AnyRunCommandState) async throws -> [MutationTestOutcome.Mutation] {
        var outcomes: [MutationTestOutcome.Mutation] = []
        outcomes.reserveCapacity(state.mutationPoints.count)
        var buildErrors = 0

        for mutationMap in state.mutationMapping {
            for mutationSchema in mutationMap.mutationSchemata {

                try? ioDelegate.switchOn(
                    schemata: mutationSchema,
                    for: state.projectXCTestRun,
                    at: state.mutatedProjectDirectoryURL
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
                    mutatedProjectDirectoryURL: state.mutatedProjectDirectoryURL
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
                    throw MuterError.mutationTestingAborted(reason: .tooManyBuildErrors)
                }
            }
        }

        return outcomes
    }

    func logFileName(
        for fileName: FileName,
        schemata: MutationSchema
    ) -> String {
        "\(fileName)_\(schemata.mutationOperatorId.rawValue)_\(schemata.position).log"
    }
}
