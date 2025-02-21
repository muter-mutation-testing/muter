import Foundation
@testable import muterCore
import SwiftSyntax

class MutationTestingDelegateSpy: Spy, MutationTestingIODelegate {
    private(set) var methodCalls: [String] = []
    private(set) var backedUpFilePaths: [String] = []
    private(set) var mutatedFileContents: [String] = []
    private(set) var mutatedFilePaths: [String] = []
    private(set) var restoredFilePaths: [String] = []

    private(set) var schematas: MutationSchemata = []
    private(set) var testRuns: [XCTestRun] = []
    private(set) var testRunPaths: [URL] = []
    private(set) var testLogs: [String] = []

    var testSuiteOutcomes: [TestSuiteOutcome]!

    func backupFile(at path: String, using swapFilePaths: [FilePath: FilePath]) {
        methodCalls.append(#function)
        backedUpFilePaths.append(path)
    }

    func writeFile(to path: String, contents: String) throws {
        methodCalls.append(#function)
        mutatedFilePaths.append(path)
        mutatedFileContents.append(contents)
    }

    func runTestSuite(
        withSchemata schemata: MutationSchema,
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) -> (
        outcome: TestSuiteOutcome,
        testLog: String
    ) {
        methodCalls.append(#function)
        testLogs.append(fileName)
        return (testSuiteOutcomes.remove(at: 0), "testLog")
    }

    func benchmarkTests(
        using configuration: MuterConfiguration,
        savingResultsIntoFileNamed fileName: String
    ) -> (
        outcome: TestSuiteOutcome,
        testLog: String
    ) {
        methodCalls.append(#function)
        testLogs.append(fileName)
        return (testSuiteOutcomes.remove(at: 0), "testLog")
    }

    func switchOn(schemata: MutationSchema, for testRun: XCTestRun, at path: URL) throws {
        methodCalls.append(#function)
        schematas.append(schemata)
        testRuns.append(testRun)
        testRunPaths.append(path)
    }

    func restoreFile(at path: String, using swapFilePaths: [FilePath: FilePath]) {
        methodCalls.append(#function)
        restoredFilePaths.append(path)
    }
}
