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

    func test_copiesWithVanishedFileToleranceAndRestoresTheDelegate() async throws {
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.mutatedProjectDirectoryURL = URL(string: "/tmp/projectName")!

        _ = try await sut.run(with: state)

        XCTAssertTrue(fileManager.delegateDuringCopy is VanishedFileTolerance)
        XCTAssertNil(fileManager.delegate)
    }

    func test_restoresTheDelegateWhenTheCopyFails() async throws {
        fileManager.errorToThrow = TestingError.stub
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.mutatedProjectDirectoryURL = URL(string: "/tmp/projectName")!

        _ = try? await sut.run(with: state)

        XCTAssertNil(fileManager.delegate)
    }

    func test_vanishedFileToleranceProceedsOnlyPastMissingFiles() {
        let tolerance = VanishedFileTolerance()
        let missing: [Error] = [
            NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError),
            NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError),
            NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT)),
            NSError(
                domain: NSCocoaErrorDomain,
                code: NSFileWriteUnknownError,
                userInfo: [NSUnderlyingErrorKey: NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT))]
            ),
        ]
        let fatal: [Error] = [
            NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError),
            NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError),
            NSError(domain: NSPOSIXErrorDomain, code: Int(EACCES)),
            TestingError.stub,
        ]

        for error in missing {
            XCTAssertTrue(
                tolerance.fileManager(.default, shouldProceedAfterError: error, copyingItemAtPath: "/src/x.lock", toPath: "/dst/x.lock"),
                "should skip \(error)"
            )
        }
        for error in fatal {
            XCTAssertFalse(
                tolerance.fileManager(.default, shouldProceedAfterError: error, copyingItemAtPath: "/src/x", toPath: "/dst/x"),
                "should stop on \(error)"
            )
        }
        XCTAssertEqual(tolerance.skippedPaths.count, missing.count)
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

    func test_whenFilesVanishDuringTheCopy_thenItReportsThemAndFinishes() async throws {
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.mutatedProjectDirectoryURL = URL(string: "/tmp/projectName")!
        fileManager.pathsVanishingDuringCopy = ["/some/projectName/.build/a.lock", "/some/projectName/.build/b.lock"]
        var reported: [String]?
        let token = notificationCenter.addObserver(
            forName: .projectCopySkippedVanishedFiles, object: nil, queue: nil
        ) { reported = $0.object as? [String] }
        defer { notificationCenter.removeObserver(token) }

        _ = try await sut.run(with: state)

        XCTAssertEqual(reported, ["/some/projectName/.build/a.lock", "/some/projectName/.build/b.lock"])
    }

    func test_whenNoFileVanishes_thenNothingIsReported() async throws {
        state.projectDirectoryURL = URL(string: "/some/projectName")!
        state.mutatedProjectDirectoryURL = URL(string: "/tmp/projectName")!
        var reported = false
        let token = notificationCenter.addObserver(
            forName: .projectCopySkippedVanishedFiles, object: nil, queue: nil
        ) { _ in reported = true }
        defer { notificationCenter.removeObserver(token) }

        _ = try await sut.run(with: state)

        XCTAssertFalse(reported)
    }
}
