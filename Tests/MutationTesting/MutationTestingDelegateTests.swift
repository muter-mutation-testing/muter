@testable import muterCore
import TestingExtensions
import XCTest

final class MutationTestingDelegateTests: MuterTestCase {
    private lazy var outputFolder = fixturesDirectory + "/MutationTestingDelegateTests"
    private lazy var outputFolderURL = URL(fileURLWithPath: outputFolder)

    private let sut = MutationTestingDelegate()

    override func setUpWithError() throws {
        try super.setUpWithError()

        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: outputFolder),
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        try FileManager.default.removeItem(atPath: outputFolder)
    }

    func test_testProcessForXcodeBuild() async throws {
        current.process = MuterProcessFactory.makeProcess

        let configuration = MuterConfiguration(
            executable: "/tmp/xcodebuild",
            arguments: [
                "-destination",
                "platform=macOS,arch=x86_64,variant=Mac Catalyst"
            ]
        )

        let schemata = try MutationSchema.make(
            filePath: "/path/fileName",
            position: .init(line: 1)
        )

        let testProcess = try await sut.testProcess(
            with: configuration,
            schemata: schemata,
            and: FileHandle(fileDescriptor: 0)
        )

        XCTAssertEqual(testProcess.arguments, [
            "test-without-building",
            "-destination",
            "platform=macOS,arch=x86_64,variant=Mac Catalyst",
            "-xctestrun",
            "muter.xctestrun"
        ])

        XCTAssertEqual(testProcess.executableURL?.path, "/tmp/xcodebuild")
    }

    func test_testProcessForSwiftBuild() async throws {
        current.process = MuterProcessFactory.makeProcess

        let configuration = MuterConfiguration(
            executable: "/tmp/swift",
            arguments: ["test"]
        )

        let schemata = try MutationSchema.make(
            filePath: "/path/fileName",
            position: .init(line: 1)
        )

        let testProcess = try await sut.testProcess(
            with: configuration,
            schemata: schemata,
            and: FileHandle(fileDescriptor: 0)
        )

        XCTAssertEqual(testProcess.environment?[schemata.id], "YES")
        // Also forwarded with the SIMCTL_CHILD_ prefix so it reaches an iOS Simulator test host
        // (CoreSimulator only propagates SIMCTL_CHILD_-prefixed vars into the simulated process).
        XCTAssertEqual(testProcess.environment?["SIMCTL_CHILD_\(schemata.id)"], "YES")
        XCTAssertEqual(testProcess.environment?[isMuterRunningKey], isMuterRunningValue)
        XCTAssertEqual(testProcess.arguments, ["test", "--skip-build"])
        XCTAssertEqual(testProcess.executableURL?.path, "/tmp/swift")
    }

    func test_makeProcess_doesNotSetMuterRunningMarker() {
        // The shared factory (used for build-for-testing too) must NOT carry IS_MUTER_RUNNING — on
        // some projects it makes xcodebuild skip writing build-request.json, breaking BuildForTesting.
        // The marker belongs only on the test process (asserted in test_testProcessForSwiftBuild).
        let process = MuterProcessFactory.makeProcess()

        XCTAssertNil(process.environment?[isMuterRunningKey])
    }

    func test_switchOn() async throws {
        let schemata = try MutationSchema.make()
        let testRun = XCTestRun()

        try await sut.switchOn(
            schemata: schemata,
            for: testRun,
            at: outputFolderURL
        )

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: outputFolderURL.appendingPathComponent("muter.xctestrun").path
            )
        )
    }

    func test_fileHandle() throws {
        let currentDirectoryPath = fileManager.currentDirectoryPath
        fileManager.changeCurrentDirectoryPath(outputFolder)

        let handleAndLogFileUrl = try sut.fileHandle(
            for: "logFileName"
        )

        XCTAssertEqual(handleAndLogFileUrl.logFileUrl.lastPathComponent, "logFileName")
        XCTAssertNotNil(handleAndLogFileUrl.handle)

        fileManager.changeCurrentDirectoryPath(currentDirectoryPath)
    }

    func test_timeout() async throws {
        let configuration = MuterConfiguration(
            executable: "/tmp/swift",
            arguments: ["test"],
            testSuiteTimeOut: 9
        )

        let schemata = try MutationSchema.make(
            filePath: "/path/fileName",
            position: .init(line: 1)
        )

        _ = await sut.runTestSuite(
            withSchemata: schemata,
            using: configuration,
            savingResultsIntoFileNamed: "logFileName"
        )

        XCTAssertTrue(testingTimeOutExecutor.withTimeLimitCalled)
        XCTAssertEqual(testingTimeOutExecutor.timeLimitPassed, 9)
    }

    func test_whenTestTimesOut_thenKillsProcessTreeAndReportsTimeout() async throws {
        let configuration = MuterConfiguration(
            executable: "/tmp/swift",
            arguments: ["test"],
            testSuiteTimeOut: 9
        )
        // Force the timeout branch (the test "ran too long").
        testingTimeOutExecutor.shouldSucceed = false

        let schemata = try MutationSchema.make(
            filePath: "/path/fileName",
            position: .init(line: 1)
        )

        let result = await sut.runTestSuite(
            withSchemata: schemata,
            using: configuration,
            savingResultsIntoFileNamed: "logFileName"
        )

        // On timeout we kill the WHOLE process tree (not just interrupt the parent), and the mutant
        // is reported as timed out rather than hanging the run forever.
        XCTAssertTrue(process.terminateTreeCalled)
        XCTAssertEqual(result.outcome, .timeout)
    }

    func test_whenTestProcessCannotBeLaunched_thenTheFailureIsReportedAsTheLog() async throws {
        let configuration = MuterConfiguration(
            executable: "swift",
            arguments: ["test", "--filter", "CalcTests"]
        )
        process.runError = NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileNoSuchFileError,
            userInfo: [NSLocalizedDescriptionKey: "The file \"swift\" doesn't exist."]
        )

        let result = await sut.benchmarkTests(
            using: configuration,
            savingResultsIntoFileNamed: "logFileName"
        )

        // A process that never launches produces no test output, so the spawn failure itself is the only
        // evidence there is. An empty log here leaves the abort message with nothing to show the user.
        XCTAssertEqual(result.outcome, .buildError)
        XCTAssertTrue(result.testLog.contains("swift"), result.testLog)
        XCTAssertTrue(result.testLog.contains("test --filter CalcTests"), result.testLog)
        XCTAssertTrue(result.testLog.contains("doesn't exist"), result.testLog)
    }

    func test_whenConfigurationHasNoTimeOut_thenRunTestsWithoutTimeOut() async throws {
        let configuration = MuterConfiguration(
            executable: "/tmp/swift",
            arguments: ["test"],
            testSuiteTimeOut: nil
        )

        let schemata = try MutationSchema.make(
            filePath: "/path/fileName",
            position: .init(line: 1)
        )

        _ = await sut.runTestSuite(
            withSchemata: schemata,
            using: configuration,
            savingResultsIntoFileNamed: "logFileName"
        )

        XCTAssertFalse(testingTimeOutExecutor.withTimeLimitCalled)
    }
}
