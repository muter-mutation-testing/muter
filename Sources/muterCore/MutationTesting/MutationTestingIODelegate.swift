import Foundation

protocol MutationTestingIODelegate {
    func backupFile(at path: String, using swapFilePaths: [FilePath: FilePath])
    func writeFile(to path: String, contents: String) throws
    func runTestSuite(using configuration: MuterConfiguration, savingResultsIntoFileNamed fileName: String) -> (outcome: TestSuiteOutcome, testLog: String)
    func restoreFile(at path: String, using swapFilePaths: [FilePath: FilePath])
    
    func runTestSuite(
        withSchemata schemata: Schemata,
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) -> (
        outcome: TestSuiteOutcome,
        testLog: String
    )
}

struct MutationTestingDelegate: MutationTestingIODelegate {
    private let notificationCenter: NotificationCenter = .default

    func backupFile(at path: String, using swapFilePaths: [FilePath: FilePath]) {
        let swapFilePath = swapFilePaths[path]!
        copySourceCode(fromFileAt: path, to: swapFilePath)
    }

    func writeFile(to path: String, contents: String) throws {
        try contents.write(toFile: path, atomically: true, encoding: .utf8)
    }

    func runTestSuite(using configuration: MuterConfiguration,
                      savingResultsIntoFileNamed fileName: String) -> (outcome: TestSuiteOutcome, testLog: String) {
        do {
            let (testProcessFileHandle, testLogUrl) = try fileHandle(for: fileName)
            defer { testProcessFileHandle.closeFile() }

            let process = try testProcess(with: configuration, and: testProcessFileHandle)
            try process.run()
            process.waitUntilExit()

            let contents = try String(contentsOf: testLogUrl)

            return (
                outcome: TestSuiteOutcome.from(testLog: contents, terminationStatus: process.terminationStatus),
                testLog: contents
            )

        } catch {
            return (.buildError, "") // this should never be executed
        }
    }

    func restoreFile(at path: String, using swapFilePaths: [FilePath: FilePath]) {
        let swapFilePath = swapFilePaths[path]!
        copySourceCode(fromFileAt: swapFilePath, to: path)
    }
    
    func runTestSuite(
        withSchemata schemata: Schemata,
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) -> (
        outcome: TestSuiteOutcome,
        testLog: String
    ) {
        do {
            let (testProcessFileHandle, testLogUrl) = try fileHandle(for: fileName)
            defer { testProcessFileHandle.closeFile() }

            let process = try testProcess(
                with: configuration,
                schemata: schemata,
                and: testProcessFileHandle
            )

            try process.run()

            process.waitUntilExit()

            let contents = try String(contentsOf: testLogUrl)

            return (
                outcome: TestSuiteOutcome.from(testLog: contents, terminationStatus: process.terminationStatus),
                testLog: contents
            )

        } catch {
            return (.buildError, "") // this should never be executed
        }
    }
    
    func testProcess(
        with configuration: MuterConfiguration,
        schemata: Schemata,
        and fileHandle: FileHandle
    ) throws -> Process {
        var commands = configuration.testCommandArguments
        
        if configuration.buildSystem == .xcodebuild {
            let destinationIndex = commands.firstIndex(of: "-destination")!
            commands = [
                "test-without-building",
                commands[destinationIndex],
                commands[destinationIndex.advanced(by: 1)],
                "-xctestrun",
                "muter.xctestrun"
            ]
        }
        
        if configuration.buildSystem == .swift {
            commands += [
                "--skip-build"
            ]
        }
        
        let process = Process()
        process.environment = [
            schemata.id: "YES"
        ]

        process.arguments = commands
        process.executableURL = URL(fileURLWithPath: configuration.testCommandExecutable)
        process.standardOutput = fileHandle
        process.standardError = fileHandle

        return process
    }
}

private extension MutationTestingDelegate {
    func copySourceCode(fromFileAt sourcePath: String, to destinationPath: String) {
        let source = sourceCode(fromFileAt: sourcePath)
        try? source?.code.description.write(toFile: destinationPath, atomically: true, encoding: .utf8)
    }

    func fileHandle(for logFileName: String) throws -> (handle: FileHandle, logFileUrl: URL) {
        let testLogUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/" + logFileName)
        try Data().write(to: testLogUrl)

        return (
            handle: try FileHandle(forWritingTo: testLogUrl),
            logFileUrl: testLogUrl
        )
    }

    func testProcess(
        with configuration: MuterConfiguration,
        and fileHandle: FileHandle
    ) throws -> Process {
        let process = Process()
        process.arguments = configuration.testCommandArguments
        process.executableURL = URL(fileURLWithPath: configuration.testCommandExecutable)
        process.standardOutput = fileHandle
        process.standardError = fileHandle

        return process
    }
}
