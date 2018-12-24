@testable import muterCore
class SourceCodeMutationDelegateSpy: Spy, SourceCodeMutationDelegate {
    private(set) var methodCalls: [String] = []
    private(set) var mutatedFileContents: [String] = []
    private(set) var mutatedFilePaths: [String] = []

    func writeFile(filePath: String, contents: String) throws {
        methodCalls.append(#function)
        mutatedFilePaths.append(filePath)
        mutatedFileContents.append(contents)
    }
}
