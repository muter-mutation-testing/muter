@testable import muterCore
import XCTest

enum TestingError: String, Error {
    case stub
}

final class CopyProjectToTempDirectoryTests: MuterTestCase {
    private let state = MutationTestState()

    private lazy var sut = CopyProjectToTempDirectory()

    func test_whenItsAbleToCopyAProjectIntoATempDirectory() async throws {
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.mutatedProjectDirectoryURL = URL(string: "/tmp/projectName")!

        _ = try await sut.run(with: state)

        XCTAssertEqual(fileManager.copyPaths.first?.source, "/some/projectName")
        XCTAssertEqual(fileManager.copyPaths.first?.dest, "/tmp/projectName")
        XCTAssertEqual(fileManager.copyPaths.count, 1)
        XCTAssertEqual(fileManager.methodCalls, ["copyItem(atPath:toPath:)"])
    }

    func test_whenTheCopyContainsModuleCaches_thenTheyAreDiscarded() async throws {
        state.projectDirectoryURL = URL(fileURLWithPath: "/some/projectName")
        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/tmp/projectName")
        process.stdoutToBeReturned = """
        /tmp/projectName/.build/arm64-apple-macosx/debug/ModuleCache
        /tmp/projectName/.build/arm64-apple-macosx/release/ModuleCache
        """

        _ = try await sut.run(with: state)

        // A module cache records the absolute path it was built under, so one carried into the copy makes
        // every compile there fail with `missing required module 'SwiftShims'`.
        XCTAssertEqual(process.executableURL?.path, "/usr/bin/find")
        XCTAssertEqual(process.arguments, ["/tmp/projectName", "-name", "ModuleCache"])
        XCTAssertEqual(fileManager.paths, [
            "/tmp/projectName/.build/arm64-apple-macosx/debug/ModuleCache",
            "/tmp/projectName/.build/arm64-apple-macosx/release/ModuleCache",
        ])
    }

    func test_whenItsUnableToCopyAProjectIntoATempDirectory() async throws {
        fileManager.errorToThrow = TestingError.stub
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.mutatedProjectDirectoryURL = URL(string: "/tmp/projectName")!

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
