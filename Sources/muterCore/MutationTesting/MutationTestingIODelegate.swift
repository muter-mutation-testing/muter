import Foundation


protocol SchemataMutationTestingIODelegate {    
    func runTestSuite(
        withSchemata schemata: Schemata,
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) -> (
        outcome: TestSuiteOutcome,
        testLog: String
    )
    
    func switchOn(
        schemata: Schemata,
        for testRun: XCTestRun,
        at path: URL
    ) throws
}

protocol MutationTestingIODelegate: SchemataMutationTestingIODelegate {
    func backupFile(at path: String, using swapFilePaths: [FilePath: FilePath])
    func writeFile(to path: String, contents: String) throws
    func runTestSuite(using configuration: MuterConfiguration, savingResultsIntoFileNamed fileName: String) -> (outcome: TestSuiteOutcome, testLog: String)
    func restoreFile(at path: String, using swapFilePaths: [FilePath: FilePath])
}

struct MutationTestingDelegate: MutationTestingIODelegate {
    private let notificationCenter: NotificationCenter = .default
    private let muterTestRunFileName = "muter.xctestrun"

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
    
    func switchOn(
        schemata: Schemata,
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
        schemata: Schemata,
        and fileHandle: FileHandle
    ) throws -> Process {
        let testCommandArguments = schemata == .null
            ? configuration.testCommandArguments
            : configuration.testWithoutBuildArguments(with: muterTestRunFileName)

        let process = Process()

        var environment = [isMuterRunningKey: isMuterRunningValue]
        if schemata != .null {
            environment[schemata.id] = "YES"
        }

        process.environment = environment
        process.arguments = testCommandArguments
        process.executableURL = URL(fileURLWithPath: configuration.testCommandExecutable)
        process.qualityOfService = .userInitiated
        process.standardOutput = fileHandle
        process.standardError = fileHandle

        return process
    }
}

extension MutationTestingDelegate {
    func copySourceCode(fromFileAt sourcePath: String, to destinationPath: String) {
        let source = sourceCode(fromFileAt: sourcePath)
        try? source?.code.description.write(toFile: destinationPath, atomically: true, encoding: .utf8)
    }

    func fileHandle(
        for logFileName: String
    ) throws -> (
        handle: FileHandle,
        logFileUrl: URL
    ) {
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

private extension MuterConfiguration {
    func testWithoutBuildArguments(with testRunFile: String) -> [String] {
        switch buildSystem {
        case .xcodebuild:
            guard let destinationIndex = testCommandArguments.firstIndex(of: "-destination") else { return testCommandArguments }
                return [
                    "test-without-building",
                    testCommandArguments[destinationIndex],
                    testCommandArguments[destinationIndex.advanced(by: 1)],
                    "-xctestrun",
                    testRunFile
                ]
        case .swift:
            return testCommandArguments + ["--skip-build"]
        case .unknown:
            return testCommandArguments
        }
    }
}
