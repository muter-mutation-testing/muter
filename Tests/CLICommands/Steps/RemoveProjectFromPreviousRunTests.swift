import XCTest

@testable import muterCore

enum RemoveTempDirectorySpecError: String, Error {
    case stub
}

final class RemoveProjectFromPreviousRunTests: XCTestCase {
    private var fileManager = FileManagerSpy()
    private var state = RunCommandState()
    private lazy var sut = RemoveProjectFromPreviousRun(fileManager: fileManager)

    func test_removeTempDirectorySucceeds() throws {
        fileManager.fileExistsToReturn = [true]
        state.tempDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")

        let result = try XCTUnwrap(sut.run(with: state).get())

        XCTAssertEqual(result, [.removeProjectFromPreviousRunCompleted])
        XCTAssertEqual(fileManager.paths, ["/some/projectName_mutated"])
        XCTAssertEqual(fileManager.methodCalls, ["fileExists(atPath:)", "removeItem(atPath:)"])
    }

    func test_failsToRemoveTempDirectory() {
        fileManager.errorToThrow = RemoveTempDirectorySpecError.stub
        fileManager.fileExistsToReturn = [true]

        state.tempDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")

        let result = sut.run(with: state)

        guard case let .failure(.removeProjectFromPreviousRunFailed(reason)) = result else {
            return XCTFail("Expected failure, got\(result)")
        }

        XCTAssertFalse(reason.isEmpty)
    }

    func test_skipStep() throws {
        fileManager.errorToThrow = RemoveTempDirectorySpecError.stub
        fileManager.fileExistsToReturn = [false]

        state.tempDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")

        let result = try XCTUnwrap(sut.run(with: state).get())

        XCTAssertEqual(result, [.removeProjectFromPreviousRunSkipped])
    }
}
