import Foundation
import SwiftSyntax

final class PerformMutationTesting: MutationStep {
    @Dependency(\.ioDelegate)
    private var ioDelegate: MutationTestingIODelegate
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.now)
    private var now: Now

    /// Parallel running
    private var availableSimulators: [String] = []
    private let queue = DispatchQueue(label: "mutation-testing-queue", attributes: .concurrent)
    private var semaphore: DispatchSemaphore?
    private let lock = NSLock()

    private let buildErrorsThreshold: Int = 5

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
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
        using state: AnyMutationTestState
    ) async throws -> [MutationTestOutcome.Mutation] {
        notificationCenter.post(name: .mutationTestingStarted, object: nil)

        let initialTime = Date()
        let (testSuiteOutcome, testLog) = ioDelegate.runTestSuite(
            withSchemata: .null,
            using: state.muterConfiguration, 
            simulatorUDID: nil,
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

        return try testMutation(using: state)
    }

    func testMutation(using state: AnyMutationTestState) throws -> [MutationTestOutcome.Mutation] {
        var outcomes: [MutationTestOutcome.Mutation] = []
        outcomes.reserveCapacity(state.mutationPoints.count)
        var buildErrors = 0

        self.semaphore = DispatchSemaphore(value: state.launchedDeviceUdids.count)
        self.availableSimulators = state.launchedDeviceUdids
        let group = DispatchGroup()

        for mutationMap in state.mutationMapping {
            for mutationSchema in mutationMap.mutationSchemata {
                semaphore?.wait() // Wait for an available simulator
                group.enter()

                queue.async {
                    var simulatorUDID: String?

                    self.lock.lock()
                    if !self.availableSimulators.isEmpty {
                        simulatorUDID = self.availableSimulators.removeFirst()
                    }
                    self.lock.unlock()

                    guard let assignedSimulator = simulatorUDID else {
                        self.semaphore?.signal()
                        group.leave()
                        return
                    }

                    defer {
                        self.lock.lock()
                        self.availableSimulators.append(assignedSimulator)
                        self.lock.unlock()
                        self.semaphore?.signal() // Release simulator
                        group.leave()
                    }

                    try? self.ioDelegate.switchOn(
                        schemata: mutationSchema,
                        for: state.projectXCTestRun,
                        at: state.mutatedProjectDirectoryURL
                    )

                    let (testSuiteOutcome, testLog) = self.ioDelegate.runTestSuite(
                        withSchemata: mutationSchema,
                        using: state.muterConfiguration,
                        simulatorUDID: assignedSimulator, // Properly assigned simulator
                        savingResultsIntoFileNamed: self.logFileName(
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

                    self.lock.lock()
                    outcomes.append(outcome)
                    if testSuiteOutcome == .buildError {
                        buildErrors += 1
                    }
                    self.lock.unlock()

                    let mutationLog = MutationTestLog(
                        mutationPoint: mutationPoint,
                        testLog: testLog,
                        timePerBuildTestCycle: .none,
                        remainingMutationPointsCount: .none
                    )

                    DispatchQueue.main.async {
                        self.notificationCenter.post(
                            name: .newMutationTestOutcomeAvailable,
                            object: outcome
                        )

                        self.notificationCenter.post(
                            name: .newTestLogAvailable,
                            object: mutationLog
                        )
                    }

                    if buildErrors >= self.buildErrorsThreshold {
                        return
                    }
                }
            }
        }

        group.wait() // Ensure all tasks complete before returning

        if buildErrors >= buildErrorsThreshold {
            throw MuterError.mutationTestingAborted(reason: .tooManyBuildErrors)
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
