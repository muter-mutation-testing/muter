@testable import muterCore
import XCTest

final class FileOperationTests: XCTestCase {
    func test_createsALoggingDirectory() {
        let fileManagerSpy = FileManagerSpy()
        let timestamp = DateComponents(
            calendar: .init(identifier: .gregorian),
            year: 2019,
            month: 5,
            day: 10,
            hour: 2,
            minute: 42
        )

        let loggingDirectory = createLoggingDirectory(
            in: "~/some/path",
            fileManager: fileManagerSpy,
            locale: Locale(identifier: "en_US"),
            timestamp: { timestamp.date! }
        )

        XCTAssertEqual(loggingDirectory, "~/some/path/muter_logs/May 10, 2019 at 2:42 AM")
        XCTAssertEqual(fileManagerSpy.methodCalls, ["createDirectory(atPath:withIntermediateDirectories:attributes:)"])
        XCTAssertEqual(fileManagerSpy.createsIntermediates, [true])
        XCTAssertEqual(fileManagerSpy.paths, ["~/some/path/muter_logs/May 10, 2019 at 2:42 AM"])
    }
}
