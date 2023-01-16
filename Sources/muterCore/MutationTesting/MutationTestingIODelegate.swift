import Foundation

protocol MutationTestingIODelegate {
    func backupFile(at path: String, using swapFilePaths: [FilePath: FilePath])
    func writeFile(to path: String, contents: String) throws
    func runTestSuite(
        using configuration: MuterConfiguration,
        activeSchemata: Schemata?,
        savingResultsIntoFileNamed fileName: String
    ) -> (outcome: TestSuiteOutcome, testLog: String)
    func restoreFile(at path: String, using swapFilePaths: [FilePath: FilePath])
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
                      activeSchemata: Schemata?,
                      savingResultsIntoFileNamed fileName: String) -> (outcome: TestSuiteOutcome, testLog: String) {
        do {
            let (testProcessFileHandle, testLogUrl) = try fileHandle(for: fileName)
            defer { testProcessFileHandle.closeFile() }

            let process = try testProcess(with: configuration,
                                          schemataId: activeSchemata?.id,
                                          and: testProcessFileHandle)
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
        schemataId: String?,
        and fileHandle: FileHandle
    ) throws -> Process {
        let process = Process()
        schemataId.map {
            process.environment = [$0: $0]
        }

        let destinationIndex = configuration.testCommandArguments.firstIndex(of: "-destination")!

        // yeah i know...i know, hold you breath :)
        if !configuration.xcTestRunCommand.isEmpty {
            process.arguments = [
                configuration.testCommandArguments[destinationIndex],
                configuration.testCommandArguments[destinationIndex + 1]
            ] + configuration.xcTestRunCommand
        } else {
            process.arguments = configuration.testCommandArguments
        }

        process.executableURL = URL(fileURLWithPath: configuration.testCommandExecutable)
        process.standardOutput = fileHandle
        process.standardError = fileHandle

        return process
    }
}
