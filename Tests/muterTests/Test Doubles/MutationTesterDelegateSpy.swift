import SwiftSyntax

class MutationTesterDelegateSpy: Spy, MutationTesterDelegate {

    private(set) var methodCalls: [String] = []
    private(set) var backedUpFilePaths: [String] = []
    private(set) var restoredFilePaths: [String] = []
    
    var testSuiteResult: MutationTester.TestSuiteResult!
    
    func backupFile(at path: String) {
        methodCalls.append(#function)
        backedUpFilePaths.append(path)
    }

    func runTestSuite() -> MutationTester.TestSuiteResult {
        methodCalls.append(#function)
        return testSuiteResult
    }
    
    func restoreFile(at path: String) {
        methodCalls.append(#function)
        restoredFilePaths.append(path)
    }
}
