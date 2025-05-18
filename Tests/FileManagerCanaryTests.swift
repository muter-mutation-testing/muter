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

            #if os(Linux)
            XCTAssertTrue(temporaryDirectory.absoluteString.contains("/tmp/TemporaryItems/"))
            #elseif os(macOS)
            XCTAssertTrue(temporaryDirectory.absoluteString.contains("/var/folders"))
            XCTAssertTrue(temporaryDirectory.absoluteString.contains("/T/TemporaryItems/"))
            #elseif os(Windows)
            XCTAssertTrue(temporaryDirectory.absoluteString.contains("\\AppData\\Local\\Temp\\"))
            #endif
        } catch {
            XCTFail("Expected no errors, but got \(error)")
        }
    }
}
