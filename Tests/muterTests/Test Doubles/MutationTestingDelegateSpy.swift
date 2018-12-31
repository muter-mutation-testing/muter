import SwiftSyntax
@testable import muterCore

class MutationTestingDelegateSpy: Spy, MutationTestingIODelegate {

    private(set) var methodCalls: [String] = []
    private(set) var backedUpFilePaths: [String] = []
	private(set) var mutatedFileContents: [String] = []
	private(set) var mutatedFilePaths: [String] = []
    private(set) var restoredFilePaths: [String] = []
    
    var testSuiteResult: TestSuiteResult!
    
    func backupFile(at path: String) {
        methodCalls.append(#function)
        backedUpFilePaths.append(path)
    }
	
	func writeFile(filePath: String, contents: String) throws {
		methodCalls.append(#function)
		mutatedFilePaths.append(filePath)
		mutatedFileContents.append(contents)
	}

    func runTestSuite() -> TestSuiteResult {
        methodCalls.append(#function)
        return testSuiteResult
    }
    
    func restoreFile(at path: String) {
        methodCalls.append(#function)
        restoredFilePaths.append(path)
    }
}
