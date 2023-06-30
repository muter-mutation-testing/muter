@testable import muterCore
import XCTest

enum TestingError: String, Error {
    case stub
}

final class CopyProjectToTempDirectoryTests: MuterTestCase {
    private let state = RunCommandState()
    private var result: Result<[RunCommandState.Change], MuterError> = .success([])
    private lazy var sut = CopyProjectToTempDirectory()

    func test_whenItsAbleToCopyAProjectIntoATempDirectory() {
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.tempDirectoryURL = URL(string: "/tmp/projectName")!

        result = sut.run(with: state)

        assertThatReturnsTheCopyToTempDirectoryCompleted()
        assertThatCopiesTheProjectToTheTempDirectory()
        assertThatCopiesTheProjectAfterCreatingTheTempDirectory()
    }

    func assertThatReturnsTheCopyToTempDirectoryCompleted() {
        guard case let .success(stateChanges) = result else {
            return XCTFail("expected success but got \(String(describing: result))")
        }

        XCTAssertEqual(stateChanges, [.copyToTempDirectoryCompleted])
    }

    func assertThatCopiesTheProjectToTheTempDirectory() {
        XCTAssertEqual(fileManager.copyPaths.first?.source, "/some/projectName")
        XCTAssertEqual(fileManager.copyPaths.first?.dest, "/tmp/projectName")
        XCTAssertEqual(fileManager.copyPaths.count, 1)
    }

    func assertThatCopiesTheProjectAfterCreatingTheTempDirectory() {
        XCTAssertEqual(fileManager.methodCalls, ["copyItem(atPath:toPath:)"])
    }

    func test_whenItsUnableToCopyAProjectIntoATempDirectory() {
        fileManager.errorToThrow = TestingError.stub
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.tempDirectoryURL = URL(string: "/tmp/projectName")!

        result = sut.run(with: state)

        guard case let .failure(.projectCopyFailed(reason)) = result else {
            XCTFail("expected success but got \(String(describing: result))")
            return
        }

        XCTAssertFalse(reason.isEmpty)
    }
}
