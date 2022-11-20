import XCTest

final class FileManagerCanaryTests: XCTestCase {
    func test_namesTemporaryFilesPredictably() {
        let volumeRoot = URL(fileURLWithPath: "/")
        do {
            let temporaryDirectory = try FileManager.default.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: volumeRoot,
                create: true
            )
            
            XCTAssertTrue(temporaryDirectory.absoluteString.contains("/var/folders"))
            XCTAssertTrue(temporaryDirectory.absoluteString.contains("/T/TemporaryItems/"))
        } catch {
            XCTFail("Expected no errors, but got \(error)")
        }
    }
}
