import Foundation

protocol MutationTestingIODelegate {
    func runTestSuite(
        withSchemata schemata: MutationSchema,
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) -> (
        outcome: TestSuiteOutcome,
        testLog: String
    )

    func benchmarkTests(
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) -> (
        outcome: TestSuiteOutcome,
        testLog: String
    )

    func switchOn(
        schemata: MutationSchema,
        for testRun: XCTestRun,
        at path: URL
    ) throws
}

struct MutationTestingDelegate: MutationTestingIODelegate {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.process)
    private var process: ProcessFactory
    @Dependency(\.testingTimeOutExecutor)
    private var testingTimeOutExecutor: TestingTimeOutExecutorFactory

    private let muterTestRunFileName = "muter.xctestrun"

    func benchmarkTests(
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) -> (
        outcome: TestSuiteOutcome,
        testLog: String
    ) {
        runTestSuite(
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
    ) -> (
        outcome: TestSuiteOutcome,
        testLog: String
    ) {
        runTestSuite(
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
    ) -> (
        outcome: TestSuiteOutcome,
        testLog: String
    ) {
        do {
            let (testProcessFileHandle, testLogUrl) = try fileHandle(for: fileName)
            defer { try? testProcessFileHandle.close() }

            let process = try testProcess(
                with: configuration,
                schemata: schemata,
                and: testProcessFileHandle
            )

            let timeOut = isBenchmark ? nil : configuration.testSuiteTimeOut
            let (outcome, contents) = try runTestProcess(process, logFileUrl: testLogUrl, withTimeOut: timeOut)

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
        withTimeOut timeOut: TimeInterval?
    ) throws -> (TestSuiteOutcome, String) {
        let executionResult = timeOut == nil
            ? try runTestProcess(process)
            : try runTestProcess(process, withTimeOut: timeOut!)

        let testExecutionLog = try String(contentsOf: logFileUrl)
        let testResult = TestSuiteOutcome.from(
            testLog: testExecutionLog,
            terminationStatus: process.terminationStatus,
            timeOutExecution: executionResult
        )

        return (testResult, testExecutionLog)
    }

    private func runTestProcess(
        _ process: Process,
        withTimeOut timeOut: TimeInterval
    ) throws -> TestingExecutionResult {
        let executor = testingTimeOutExecutor()

        return try executor.runTestProcess(process, withTimeOut: timeOut)
    }

    private func runTestProcess(_ process: Process) throws -> TestingExecutionResult {
        try process.run()
        process.waitUntilExit()

        return .success
    }

    func switchOn(
        schemata: MutationSchema,
        for testRun: XCTestRun,
        at path: URL
    ) throws {
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
    ) throws -> Process {
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
