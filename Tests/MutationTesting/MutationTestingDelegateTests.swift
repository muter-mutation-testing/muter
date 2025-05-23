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
        XCTAssertEqual(testProcess.environment?[isMuterRunningKey], isMuterRunningValue)
        XCTAssertEqual(testProcess.arguments, ["test", "--skip-build"])
        XCTAssertEqual(testProcess.executableURL?.path, "/tmp/swift")
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

    func test_timeOut() async throws {
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
