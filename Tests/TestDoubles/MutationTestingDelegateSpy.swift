import SwiftSyntax
@testable import muterCore

class MutationTestingDelegateSpy: Spy, MutationTestingIODelegate {

    private(set) var methodCalls: [String] = []
    private(set) var backedUpFilePaths: [String] = []
    private(set) var mutatedFileContents: [String] = []
    private(set) var mutatedFilePaths: [String] = []
    private(set) var restoredFilePaths: [String] = []
    private(set) var abortReasons: [MutationTestingAbortReason] = []

    var testSuiteOutcomes: [TestSuiteOutcome]!

    func backupFile(at path: String) {
        methodCalls.append(#function)
        backedUpFilePaths.append(path)
    }

    func writeFile(to path: String, contents: String) throws {
        methodCalls.append(#function)
        mutatedFilePaths.append(path)
        mutatedFileContents.append(contents)
    }

    func runTestSuite(savingResultsIntoFileNamed: String) -> (outcome: TestSuiteOutcome, testLog: String) {
        methodCalls.append(#function)
        return (testSuiteOutcomes.remove(at: 0), "testLog")
    }

    func restoreFile(at path: String) {
        methodCalls.append(#function)
        restoredFilePaths.append(path)
    }

    func abortTesting(reason: MutationTestingAbortReason) {
        methodCalls.append(#function)
        abortReasons.append(reason)
    }
}
