import Foundation
import SwiftSyntax

protocol MutationTestingIODelegate {
    func backupFile(at path: String)
    func writeFile(filePath: String, contents: String) throws
    func runTestSuite() -> TestSuiteResult
    func restoreFile(at path: String)
}

struct MutationTestOutcome: Equatable {
    let testSuiteResult: TestSuiteResult
    let appliedMutation: String
    let filePath: String
    let position: AbsolutePosition
}

enum TestSuiteResult: String {
    case passed
    case failed

    var asMutationTestOutcome: String {
        switch self {
        case .passed:
            return "failed"
        default:
            return "passed"
        }
    }
}

func performMutationTesting(using operators: [MutationOperator], delegate: MutationTestingIODelegate) -> [MutationTestOutcome] {

    return operators.enumerated().map { index, `operator` in
        let filePath = `operator`.filePath
        print("Testing mutation operator in \(URL(fileURLWithPath: filePath).lastPathComponent)")
        print("There are \(operators.count - (index + 1)) left to apply")

        delegate.backupFile(at: filePath)

        let mutatedSource = `operator`.apply()
        try! delegate.writeFile(filePath: filePath, contents: mutatedSource.description)

        let result = delegate.runTestSuite()
        delegate.restoreFile(at: filePath)

        return MutationTestOutcome(testSuiteResult: result,
                                   appliedMutation: `operator`.id.rawValue,
                                   filePath: filePath,
                                   position: `operator`.position)
    }
}

// MARK - Mutation Score Calculation

func mutationScore(from testResults: [TestSuiteResult]) -> Int {
    guard testResults.count >= 1 else {
        return -1
    }

    let numberOfFailures = Double(testResults.include { $0 == .failed }.count)
    return Int((numberOfFailures / Double(testResults.count)) * 100.0)
}

func mutationScoreOfFiles(from outcomes: [MutationTestOutcome]) -> [String: Int] {
    var mutationScores: [String: Int] = [:]

    let filePaths = outcomes.map { $0.filePath }.deduplicated()
    for filePath in filePaths {
        let relevantTestResults = outcomes.include { $0.filePath == filePath }
        let testSuiteResults = relevantTestResults.map { $0.testSuiteResult }
        mutationScores[filePath] = mutationScore(from: testSuiteResults)
    }

    return mutationScores
}

// MARK - Mutation Testing I/O Delegate
@available(OSX 10.13, *)
struct MutationTestingDelegate: MutationTestingIODelegate {

    let configuration: MuterConfiguration
    let swapFilePathsByOriginalPath: [String: String]

    func backupFile(at path: String) {
        let swapFilePath = swapFilePathsByOriginalPath[path]!
        copySourceCode(fromFileAt: path, to: swapFilePath)
    }

    func writeFile(filePath: String, contents: String) throws {
        try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
    }

    func runTestSuite() -> TestSuiteResult {
        do {
            let (process, fileHandle, url) = try testProcess(with: configuration)
            try process.run()
            
            process.waitUntilExit()
            fileHandle.closeFile()
            
            let result = try String(contentsOf: url)
            return result.contains("** TEST FAILED **") ? .failed : .passed

        } catch {
            printMessage("Muter encountered an error running your test suite and can't continue\n\(error)")
            exit(1)
        }
    }

    func restoreFile(at path: String) {
        let swapFilePath = swapFilePathsByOriginalPath[path]!
        copySourceCode(fromFileAt: swapFilePath, to: path)
    }
}

@available(OSX 10.13, *)
private extension MutationTestingDelegate {
    func testProcess(with configuration: MuterConfiguration) throws -> (Process, FileHandle, URL) {
        let testLogFileName = UUID().description + ".log"
        let testLogUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/" + testLogFileName)
        try Data().write(to: testLogUrl)
        
        let fileHandle = try FileHandle(forWritingTo: testLogUrl)

        let process = Process()
        process.arguments = configuration.testCommandArguments
        process.executableURL = URL(fileURLWithPath: configuration.testCommandExecutable)
        process.standardOutput = fileHandle
        process.standardError = fileHandle
        return (process, fileHandle, testLogUrl)
    }
}
