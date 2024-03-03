@testable import muterCore
import XCTest

enum RemoveTempDirectorySpecError: String, Error {
    case stub
}

final class PreviousRunCleanUpTests: MuterTestCase {
    private var state = RunCommandState()
    private lazy var sut = PreviousRunCleanUp()

    func test_removeTempDirectorySucceeds() async throws {
        fileManager.fileExistsToReturn = [true]
        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")

        let result = try await sut.run(with: state)

        XCTAssertEqual(result, [])
        XCTAssertEqual(fileManager.paths, ["/some/projectName_mutated"])
        XCTAssertEqual(fileManager.methodCalls, ["fileExists(atPath:)", "removeItem(atPath:)"])
    }

    func test_failsToRemoveTempDirectory() async throws {
        fileManager.errorToThrow = RemoveTempDirectorySpecError.stub
        fileManager.fileExistsToReturn = [true]

        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")

        try await assertThrowsMuterError(
            await sut.run(with: state)
        ) { error in
            guard case let .removeProjectFromPreviousRunFailed(reason) = error else {
                XCTFail("Expected removeProjectFromPreviousRunFailed, got \(error)")
                return
            }

            XCTAssertFalse(reason.isEmpty)
        }
    }

    func test_skipStep() async throws {
        fileManager.errorToThrow = RemoveTempDirectorySpecError.stub
        fileManager.fileExistsToReturn = [false]

        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/some/projectName_mutated")

        let result = try await sut.run(with: state)

        XCTAssertEqual(result, [])
    }
}
