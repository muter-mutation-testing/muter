import Foundation

final class WriteFileSpy {
    private(set) var writeFileCalled = false
    private(set) var contentPassed: String?
    private(set) var pathPassed: String?

    func writeFile(_ content: String, _ path: String) throws {
        writeFileCalled = true
        contentPassed = content
        pathPassed = path
    }
}
