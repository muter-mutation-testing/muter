import Foundation
import SwiftSyntax

struct PerformMutationTesting: MutationStep {
    @Dependency(\.ioDelegate)
    private var ioDelegate: MutationTestingIODelegate
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.now)
    private var now: Now

    private let buildErrorsThreshold: Int = 5

    /// With no `mutationTestTimeout`, a mutant's test run may take this many times the baseline run
    /// before it is stopped, but never less than `minimumDefaultTimeout` seconds. A mutant that makes
    /// the code loop forever then costs a few baseline runs rather than the whole run.
    static let defaultTimeoutMultiplier: TimeInterval = 3
    static let minimumDefaultTimeout: TimeInterval = 10

    /// Clones the mutated project for each extra parallel worker, and removes the clones afterwards.
    /// Injected so tests don't touch the disk.
    private let makeWorkerDirectories: (_ mutatedProject: URL, _ count: Int) throws -> [URL]
    private let removeWorkerDirectories: (_ directories: [URL]) -> Void

    init(
        makeWorkerDirectories: @escaping (URL, Int) throws -> [URL] = PerformMutationTesting.cloneMutatedProject,
        removeWorkerDirectories: @escaping ([URL]) -> Void = PerformMutationTesting.removeClones
    ) {
        self.makeWorkerDirectories = makeWorkerDirectories
        self.removeWorkerDirectories = removeWorkerDirectories
    }

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
        let (testSuiteOutcome, testLog) = await ioDelegate.benchmarkTests(
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

        let configuration = state.muterConfiguration.withDefaultTestSuiteTimeout(
            max(timePerBuildTestCycle * Self.defaultTimeoutMultiplier, Self.minimumDefaultTimeout)
        )
        let jobs = state.mutationMapping.flatMap { mutationMap in
            mutationMap.mutationSchemata.map { MutantJob(fileName: mutationMap.fileName, schema: $0) }
        }
        let workers = min(configuration.workerCount, jobs.count)

        return workers > 1
            ? try await testMutationsInParallel(jobs, workers: workers, using: state, configuration: configuration)
            : try await testMutations(jobs, using: state, configuration: configuration)
    }

    struct MutantJob {
        let fileName: FileName
        let schema: MutationSchema
    }

    func testMutations(
        _ jobs: [MutantJob],
        using state: AnyMutationTestState,
        configuration: MuterConfiguration
    ) async throws -> [MutationTestOutcome.Mutation] {
        var outcomes: [MutationTestOutcome.Mutation] = []
        outcomes.reserveCapacity(jobs.count)
        var buildErrors = 0

        for job in jobs {
            try? await ioDelegate.switchOn(
                schemata: job.schema,
                for: state.projectXCTestRun,
                at: state.mutatedProjectDirectoryURL
            )

            let (testSuiteOutcome, testLog) = await ioDelegate.runTestSuite(
                withSchemata: job.schema,
                using: configuration,
                savingResultsIntoFileNamed: logFileName(for: job.fileName, schemata: job.schema)
            )

            outcomes.append(
                try record(job, testSuiteOutcome, testLog, using: state, buildErrors: &buildErrors)
            )
        }

        return outcomes
    }

    /// Tests `jobs` on `workers` test processes at once, each in its own clone of the mutated project:
    /// `swift test` locks the package's build directory, so two runs can't share one. Every mutant is
    /// switched on by its own process's environment, so the clones never need rewriting. Outcomes are
    /// recorded, and their notifications posted, as they finish; they're returned in `jobs` order.
    func testMutationsInParallel(
        _ jobs: [MutantJob],
        workers: Int,
        using state: AnyMutationTestState,
        configuration: MuterConfiguration
    ) async throws -> [MutationTestOutcome.Mutation] {
        let clones = try makeWorkerDirectories(state.mutatedProjectDirectoryURL, workers - 1)
        defer { removeWorkerDirectories(clones) }
        let directories = [state.mutatedProjectDirectoryURL] + clones

        var outcomes = [MutationTestOutcome.Mutation?](repeating: nil, count: jobs.count)
        var buildErrors = 0

        try await withThrowingTaskGroup(
            of: (index: Int, directory: URL, outcome: TestSuiteOutcome, log: String).self
        ) { group in
            var nextJob = 0
            func start(_ index: Int, in directory: URL) {
                let job = jobs[index]
                let fileName = logFileName(for: job.fileName, schemata: job.schema)
                group.addTask {
                    let (outcome, log) = await ioDelegate.runTestSuite(
                        withSchemata: job.schema,
                        using: configuration,
                        savingResultsIntoFileNamed: fileName,
                        workingDirectory: directory
                    )
                    return (index, directory, outcome, log)
                }
            }

            for directory in directories {
                start(nextJob, in: directory)
                nextJob += 1
            }

            while let finished = try await group.next() {
                outcomes[finished.index] = try record(
                    jobs[finished.index], finished.outcome, finished.log,
                    using: state, buildErrors: &buildErrors
                )
                if nextJob < jobs.count {
                    start(nextJob, in: finished.directory)
                    nextJob += 1
                }
            }
        }

        return outcomes.compactMap { $0 }
    }

    /// Builds `job`'s outcome, posts its notifications, and aborts after `buildErrorsThreshold`
    /// build errors in a row.
    func record(
        _ job: MutantJob,
        _ testSuiteOutcome: TestSuiteOutcome,
        _ testLog: String,
        using state: AnyMutationTestState,
        buildErrors: inout Int
    ) throws -> MutationTestOutcome.Mutation {
        let mutationPoint = MutationPoint(
            mutationOperatorId: job.schema.mutationOperatorId,
            filePath: job.schema.filePath,
            position: job.schema.position
        )

        let outcome = MutationTestOutcome.Mutation(
            testSuiteOutcome: testSuiteOutcome,
            mutationPoint: mutationPoint,
            mutationSnapshot: job.schema.snapshot,
            originalProjectDirectoryUrl: state.projectDirectoryURL,
            mutatedProjectDirectoryURL: state.mutatedProjectDirectoryURL
        )

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
        return outcome
    }

    func logFileName(
        for fileName: FileName,
        schemata: MutationSchema
    ) -> String {
        "\(fileName)_\(schemata.mutationOperatorId.rawValue)_\(schemata.position).log"
    }
}

extension PerformMutationTesting {
    struct WorkerDirectoryError: Error, CustomStringConvertible {
        let clone: URL
        let status: Int32

        var description: String {
            "Muter could not clone the mutated project to \(clone.path) for a parallel worker (cp exited \(status))."
        }
    }

    /// One clone of `project` per extra worker, next to it as `<name>_worker<n>`. On macOS `cp -c`
    /// clones on APFS, so even a large build directory copies in seconds and takes no extra space.
    static func cloneMutatedProject(_ project: URL, count: Int) throws -> [URL] {
        guard count > 0 else { return [] }
        return try (1...count).map { index in
            let clone = project.deletingLastPathComponent()
                .appendingPathComponent("\(project.lastPathComponent)_worker\(index)")
            try? FileManager.default.removeItem(at: clone)
            #if os(macOS)
            let copy = Foundation.Process()
            copy.executableURL = URL(fileURLWithPath: "/bin/cp")
            copy.arguments = ["-c", "-R", project.path, clone.path]
            try copy.run()
            copy.waitUntilExit()
            guard copy.terminationStatus == 0 else {
                throw WorkerDirectoryError(clone: clone, status: copy.terminationStatus)
            }
            #else
            try FileManager.default.copyItem(at: project, to: clone)
            #endif
            return clone
        }
    }

    static func removeClones(_ directories: [URL]) {
        for directory in directories {
            try? FileManager.default.removeItem(at: directory)
        }
    }
}
