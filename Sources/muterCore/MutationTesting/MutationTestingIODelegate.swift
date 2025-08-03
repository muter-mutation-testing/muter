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
            return (.buildError, "") // this should never be executed
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
            process.interrupt()
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

        if schemata != .null {
            process.environment?[schemata.id] = "YES"
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
