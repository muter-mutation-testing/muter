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
            forProjectAt: "~/some/path",
            fileManager: fileManagerSpy,
            locale: Locale(identifier: "en_US"),
            timestamp: { timestamp.date! }
        )

        XCTAssertEqual(loggingDirectory, "~/some/path_muter_logs/May 10, 2019 at 2:42 AM")
        XCTAssertEqual(fileManagerSpy.methodCalls, ["createDirectory(atPath:withIntermediateDirectories:attributes:)"])
        XCTAssertEqual(fileManagerSpy.createsIntermediates, [true])
        XCTAssertEqual(fileManagerSpy.paths, ["~/some/path_muter_logs/May 10, 2019 at 2:42 AM"])
    }

    // Logs go next to the project, like the `_mutated` copy, never inside it:
    // a `muter_logs` folder in the project is picked up by the next project
    // copy and shows up as untracked files in the user's repository.
    func test_loggingDirectoryIsASiblingOfTheProject() {
        let fileManagerSpy = FileManagerSpy()

        let loggingDirectory = createLoggingDirectory(
            forProjectAt: "/Users/me/projects/App/",
            fileManager: fileManagerSpy,
            locale: Locale(identifier: "en_US"),
            timestamp: { Date(timeIntervalSince1970: 0) }
        )

        XCTAssertTrue(loggingDirectory.hasPrefix("/Users/me/projects/App_muter_logs/"), loggingDirectory)
        XCTAssertFalse(loggingDirectory.hasPrefix("/Users/me/projects/App/"), loggingDirectory)
    }
}
