import SwiftSyntax
@testable import muterCore

class MutationTestingDelegateSpy: Spy, MutationTestingIODelegate {
    private(set) var methodCalls: [String] = []
    private(set) var backedUpFilePaths: [String] = []
    private(set) var mutatedFileContents: [String] = []
    private(set) var mutatedFilePaths: [String] = []
    private(set) var restoredFilePaths: [String] = []

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

    func runTestSuite(using configuration: MuterConfiguration, savingResultsIntoFileNamed fileName: String) -> (outcome: TestSuiteOutcome, testLog: String) {
        methodCalls.append(#function)
        return (testSuiteOutcomes.remove(at: 0), "testLog")
    }
    
    func runTestSuite(withSchemata schemata: muterCore.Schemata, using configuration: muterCore.MuterConfiguration, savingResultsIntoFileNamed fileName: String) -> (outcome: muterCore.TestSuiteOutcome, testLog: String) {
        return (testSuiteOutcomes.remove(at: 0), "testLog")
    }
    
    func restoreFile(at path: String, using swapFilePaths: [FilePath: FilePath]) {
        methodCalls.append(#function)
        restoredFilePaths.append(path)
    }
}
