@testable import muterCore
import XCTest

enum RemoveTempDirectorySpecError: String, Error {
    case stub
}

final class RemoveProjectFromPreviousRunTests: MuterTestCase {
    private var state = RunCommandState()
    private lazy var sut = RemoveProjectFromPreviousRun()

    func test_removeTempDirectorySucceeds() throws {
        fileManager.fileExistsToReturn = [true]
        state.tempDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")

        let result = try XCTUnwrap(sut.run(with: state).get())

        XCTAssertEqual(result, [])
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

        XCTAssertEqual(result, [])
    }
}
