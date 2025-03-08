import Foundation

protocol MutationTestingIODelegate {
    func runTestSuite(
        withSchemata schemata: MutationSchema,
        using configuration: MuterConfiguration,
        simulatorUDID: String?,
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

    private let muterTestRunFileName = "muter.xctestrun"

    func runTestSuite(
        withSchemata schemata: MutationSchema,
        using configuration: MuterConfiguration,
        simulatorUDID: String?,
        savingResultsIntoFileNamed fileName: String
    ) -> (
        outcome: TestSuiteOutcome,
        testLog: String
    ) {
        do {
            let (testProcessFileHandle, testLogUrl) = try fileHandle(for: fileName)
            defer { try? testProcessFileHandle.close() }

            let process = try testProcess(
                simulatorUDID: simulatorUDID,
                with: configuration,
                schemata: schemata,
                and: testProcessFileHandle
            )

            try process.run()

            process.waitUntilExit()

            let contents = try String(contentsOf: testLogUrl)

            return (
                outcome: TestSuiteOutcome.from(
                    testLog: contents,
                    terminationStatus: process.terminationStatus
                ),
                testLog: contents
            )

        } catch {
            return (.buildError, "") // this should never be executed
        }
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

        let testRunFileName = "muter" + "_\(schemata.fileName)" + ".xctestrun"
        try data.write(
            to: path.appendingPathComponent(testRunFileName)
        )
    }

    func testProcess(
        simulatorUDID: String?,
        with configuration: MuterConfiguration,
        schemata: MutationSchema,
        and fileHandle: FileHandle
    ) throws -> Process {
        let testRunFileName = "muter" + "_\(schemata.fileName)" + ".xctestrun"
        var testCommandArguments = schemata == .null
            ? configuration.testCommandArguments
        : configuration.testWithoutBuildArguments(
            with: testRunFileName,
            simulatorUDID: simulatorUDID
        )

        let process = process()

        if schemata != .null {
            process.environment?[schemata.id] = "YES"
            let testTarget = configuration.testTarget
            let testFileName = createTestFileName(from: schemata.fileName, testFileSuffix: configuration.testFileSuffix)
            testCommandArguments.append("-only-testing:\(testTarget)/\(testFileName)")
        }

        process.arguments = testCommandArguments
        process.executableURL = URL(fileURLWithPath: configuration.testCommandExecutable)
        process.standardOutput = fileHandle
        process.standardError = fileHandle

        return process
    }

    private func createTestFileName(
        from fileName: String,
        testFileSuffix: String
    ) -> String {
        // Split the file name into name and extension components
        let fileURL = URL(fileURLWithPath: fileName)
        let baseName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension
        
        // Ensure the file name has a valid extension
        guard !baseName.isEmpty, !fileExtension.isEmpty else {
            fatalError("Can not empty")
        }

        let testFileName = "\(baseName)\(testFileSuffix)"
        return testFileName
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
