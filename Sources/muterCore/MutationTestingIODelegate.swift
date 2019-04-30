import Foundation

protocol MutationTestingIODelegate {
    func backupFile(at path: String)
    func writeFile(to path: String, contents: String) throws
    func runTestSuite(savingResultsIntoFileNamed fileName: String) -> TestSuiteOutcome
    func restoreFile(at path: String)
    func abortTesting(reason: MutationTestingAbortReason)
}

enum MutationTestingAbortReason: Equatable {
    case initialTestingFailed
    case tooManyBuildErrors
    case unknownError(String)
}

// MARK - Mutation Testing I/O Delegate
@available(OSX 10.13, *)
struct MutationTestingDelegate: MutationTestingIODelegate {

    let configuration: MuterConfiguration
    let swapFilePathsByOriginalPath: [String: String]

    private let notificationCenter: NotificationCenter = .default

    func backupFile(at path: String) {
        let swapFilePath = swapFilePathsByOriginalPath[path]!
        copySourceCode(fromFileAt: path, to: swapFilePath)
    }

    func writeFile(to path: String, contents: String) throws {
        try contents.write(toFile: path, atomically: true, encoding: .utf8)
    }

    func runTestSuite(savingResultsIntoFileNamed fileName: String) -> TestSuiteOutcome {
        do {
            let (testProcessFileHandle, testLogUrl) = try fileHandle(for: fileName)

            let process = try testProcess(with: configuration, and: testProcessFileHandle)
            try process.run()
            process.waitUntilExit()
            testProcessFileHandle.closeFile()

            let contents = try String(contentsOf: testLogUrl)

            notificationCenter.post(name: .newTestLogAvailable, object: (testLogUrl.lastPathComponent, contents))

            return TestSuiteOutcome.from(testLog: contents)

        } catch {
            abortTesting(reason: .unknownError(error.localizedDescription))
            return .buildError // this should never be executed
        }
    }

    func restoreFile(at path: String) {
        let swapFilePath = swapFilePathsByOriginalPath[path]!
        copySourceCode(fromFileAt: swapFilePath, to: path)
    }

    func abortTesting(reason: MutationTestingAbortReason) {
        let message: String
        switch reason {
        case .initialTestingFailed:
            message = """
            Muter noticed that your test suite initially failed to compile or produced a test failure.

            This is usually due to misconfiguring the "executable" and "arguments" options inside of your muter.conf.json.
            Alternatively, it could mean you have a nondeterministic test failure in your test suite.

            We recommend you try your settings out in a terminal prior to using Muter for the best configuration experience.
            We also recommend removing tests which you know to be flaky from the set of tests that Muter exercises.

            If you believe that you found a bug and can reproduce it, or simply need help getting started, please consider opening an issue
            at https://github.com/SeanROlszewski/muter
            """

        case .tooManyBuildErrors:
            message = """
            Muter noticed the last 5 attempts to apply a mutation operator resulted in a build error within your code base.
            This is considered unlikely and abnormal. If you can reproduce this, please consider filing an issue at
            https://github.com/SeanROlszewski/muter/issues/
            """

        case .unknownError(let error):
            message = "Muter encountered an error running your test suite and can't continue\n\(error)"
        }

        notificationCenter.post(name: .mutationTestingAborted, object: message)
    }
}

@available(OSX 10.13, *)
private extension MutationTestingDelegate {

    func fileHandle(for logFileName: String) throws -> (handle: FileHandle, logFileUrl: URL) {
        let testLogUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/" + logFileName)
        try Data().write(to: testLogUrl)

        return (
            handle: try FileHandle(forWritingTo: testLogUrl),
            logFileUrl: testLogUrl
        )
    }

    func testProcess(with configuration: MuterConfiguration, and fileHandle: FileHandle) throws -> Process {

        let process = Process()
        process.arguments = configuration.testCommandArguments
        process.executableURL = URL(fileURLWithPath: configuration.testCommandExecutable)
        process.standardOutput = fileHandle
        process.standardError = fileHandle

        return process
    }
}
