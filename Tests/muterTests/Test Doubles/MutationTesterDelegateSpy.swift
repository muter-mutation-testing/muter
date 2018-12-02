import SwiftSyntax

class MutationTesterDelegateSpy: Spy, MutationTesterDelegate {

    private(set) var methodCalls: [String] = []
    
    private(set) var updatedFilePaths: [String] = []
    var sourceFileSyntax: SourceFileSyntax!
    var testSuiteResult: MutationTester.TestSuiteResult!
    
    func sourceFromFile(at path: String) -> SourceFileSyntax? {
        methodCalls.append(#function)
        return sourceFileSyntax
    }
    
    func backupFile(at path: String) {
        methodCalls.append(#function)
    }
    
    func writeFile(filePath: String, contents: String) {
        methodCalls.append(#function)
        updatedFilePaths.append(filePath)
    }
    
    func runTestSuite() -> MutationTester.TestSuiteResult {
        methodCalls.append(#function)
        return testSuiteResult
    }
    
    func restoreFile(at path: String) {
        methodCalls.append(#function)
    }
}
