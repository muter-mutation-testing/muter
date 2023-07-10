@testable import muterCore
import XCTest

enum TestingError: String, Error {
    case stub
}

final class CopyProjectToTempDirectoryTests: MuterTestCase {
    private let state = RunCommandState()

    private lazy var sut = CopyProjectToTempDirectory()

    func test_whenItsAbleToCopyAProjectIntoATempDirectory() async throws {
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.tempDirectoryURL = URL(string: "/tmp/projectName")!

        let result = try await sut.run(with: state)

        XCTAssertEqual(result, [.copyToTempDirectoryCompleted])

        XCTAssertEqual(fileManager.copyPaths.first?.source, "/some/projectName")
        XCTAssertEqual(fileManager.copyPaths.first?.dest, "/tmp/projectName")
        XCTAssertEqual(fileManager.copyPaths.count, 1)
        XCTAssertEqual(fileManager.methodCalls, ["copyItem(atPath:toPath:)"])
    }

    func test_whenItsUnableToCopyAProjectIntoATempDirectory() async throws {
        fileManager.errorToThrow = TestingError.stub
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.tempDirectoryURL = URL(string: "/tmp/projectName")!

        try await assertThrowsMuterError(
            await sut.run(with: state)
        ) { error in
            guard case let .projectCopyFailed(reason) = error else {
                XCTFail("Expected projectCopyFailed, got \(error)")
                return
            }

            XCTAssertFalse(reason.isEmpty)
        }
    }
}
