import Foundation

protocol MutationTestingIODelegate {
    func runTestSuite(
        withSchemata schemata: MutationSchema,
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) async -> (
        outcome: TestSuiteOutcome,
        testLog: String
    )

    func benchmarkTests(
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) async -> (
        outcome: TestSuiteOutcome,
        testLog: String
    )

    func switchOn(
        schemata: MutationSchema,
        for testRun: XCTestRun,
        at path: URL
    ) async throws
}

struct MutationTestingDelegate: MutationTestingIODelegate {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.process)
    private var process: ProcessFactory
    @Dependency(\.testingTimeOutExecutor)
    private var testingTimeOutExecutor: TestingTimeoutExecutorFactory

    private let muterTestRunFileName = "muter.xctestrun"

    func benchmarkTests(
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) async -> (
        outcome: TestSuiteOutcome,
        testLog: String
    ) {
        await runTestSuite(
            withSchemata: .null,
            using: configuration,
            savingResultsIntoFileNamed: fileName,
            isBenchmark: true
        )
    }

    func runTestSuite(
        withSchemata schemata: MutationSchema,
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) async -> (
        outcome: TestSuiteOutcome,
        testLog: String
    ) {
        await runTestSuite(
            withSchemata: schemata,
            using: configuration,
            savingResultsIntoFileNamed: fileName,
            isBenchmark: false
        )
    }

    private func runTestSuite(
        withSchemata schemata: MutationSchema,
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String,
        isBenchmark: Bool
    ) async -> (
        outcome: TestSuiteOutcome,
        testLog: String
    ) {
        do {
            let (testProcessFileHandle, testLogUrl) = try fileHandle(for: fileName)
            defer { try? testProcessFileHandle.close() }

            let process = try await testProcess(
                with: configuration,
                schemata: schemata,
                and: testProcessFileHandle
            )

            let timeout = isBenchmark ? nil : configuration.testSuiteTimeout
            let (outcome, contents) = try await runTestProcess(process, logFileUrl: testLogUrl, withTimeout: timeout)

            return (
                outcome: outcome,
                testLog: contents
            )

        } catch {
            // Reaching here means the test command never ran — the log file couldn't be opened, or
            // the process failed to spawn. There is no test output to report, so the thrown error is
            // the only evidence of what went wrong; return it as the log rather than an empty string,
            // which leaves the caller with nothing to show the user.
            return (
                .buildError,
                """
                Muter could not run your test command and captured no test output.

                  executable: \(configuration.testCommandExecutable)
                  arguments: \(configuration.testCommandArguments.joined(separator: " "))
                  working directory: \(FileManager.default.currentDirectoryPath)

                \(error.localizedDescription)
                """
            )
        }
    }

    private func runTestProcess(
        _ process: Process,
        logFileUrl: URL,
        withTimeout timeout: TimeInterval?
    ) async throws -> (TestSuiteOutcome, String) {
        let executionResult = await timeout == nil
            ? try runTestProcess(process)
            : try runTestProcess(process, withTimeout: timeout!)

        let testExecutionLog = try String(contentsOf: logFileUrl)
        let testResult = TestSuiteOutcome.from(
            testLog: testExecutionLog,
            terminationStatus: process.terminationStatus,
            timeoutExecution: executionResult
        )

        return (testResult, testExecutionLog)
    }

    private func runTestProcess(
        _ process: Process,
        withTimeout timeout: TimeInterval
    ) async throws -> TestingExecutionResult {
        try await testingTimeOutExecutor().withTimeLimit(timeout) {
            try process.run()
            process.waitUntilExit()
            return .success
        } timeoutHandler: {
            // Kill the whole process tree, not just the launched command — see terminateTree().
            process.terminateTree()
            return .timeout
        }
    }

    private func runTestProcess(_ process: Process) async throws -> TestingExecutionResult {
        try process.run()
        process.waitUntilExit()

        return .success
    }

    func switchOn(
        schemata: MutationSchema,
        for testRun: XCTestRun,
        at path: URL
    ) async throws {
        let updated = testRun.updateEnvironmentVariable(
            setting: schemata.id
        )

        let data = try PropertyListSerialization.data(
            fromPropertyList: updated,
            format: .xml,
            options: 0
        )

        try data.write(
            to: path.appendingPathComponent(muterTestRunFileName)
        )
    }

    func testProcess(
        with configuration: MuterConfiguration,
        schemata: MutationSchema,
        and fileHandle: FileHandle
    ) async throws -> Process {
        let testCommandArguments = schemata == .null
            ? configuration.testCommandArguments
            : configuration.testWithoutBuildArguments(with: muterTestRunFileName)

        let process = process()

        // Set the muter marker only on the TEST process, not the shared build process (see
        // MuterProcessFactory) — it's not needed at build time and setting it there can suppress
        // xcodebuild's build-request.json.
        process.environment?[isMuterRunningKey] = isMuterRunningValue

        if schemata != .null {
            process.environment?[schemata.id] = "YES"
            // Also forward the activation var into an iOS Simulator test host. When xcodebuild spawns
            // tests in the simulator, CoreSimulator only propagates env vars prefixed `SIMCTL_CHILD_`
            // into the simulated process; a bare var set on this (parent) process never reaches the
            // test host, so the mutant wouldn't activate. Harmless for non-simulator (swift/macOS) runs,
            // which read the bare var directly. Complements the xctestrun `EnvironmentVariables` path.
            process.environment?["SIMCTL_CHILD_\(schemata.id)"] = "YES"
        }

        process.arguments = testCommandArguments
        process.executableURL = URL(fileURLWithPath: configuration.testCommandExecutable)
        process.standardOutput = fileHandle
        process.standardError = fileHandle

        return process
    }

    func fileHandle(
        for logFileName: String
    ) throws -> (
        handle: FileHandle,
        logFileUrl: URL
    ) {
        let testLogUrl = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath + "/" + logFileName
        )
        try Data().write(to: testLogUrl)

        return try (
            handle: FileHandle(forWritingTo: testLogUrl),
            logFileUrl: testLogUrl
        )
    }
}
