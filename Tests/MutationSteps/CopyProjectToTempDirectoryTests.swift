@testable import muterCore
import XCTest

enum TestingError: String, Error {
    case stub
}

final class CopyProjectToTempDirectoryTests: MuterTestCase {
    private let state = MutationTestState()

    private lazy var sut = CopyProjectToTempDirectory()

    /// Real on-disk source tree for the happy-path test. The production
    /// code walks the source with `FileManager.default.enumerator`, so the
    /// source must actually exist; the destination side still goes through
    /// the injected `FileManagerSpy`, which records intent without touching
    /// disk.
    private var sourceRoot: URL?

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        if let sourceRoot {
            try? FileManager.default.removeItem(at: sourceRoot)
        }
    }

    func test_whenItsAbleToCopyAProjectIntoATempDirectory() async throws {
        let source = try makeSourceTree()
        let destination = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        )
        .appendingPathComponent("muter-copy-dest-\(UUID().uuidString)")

        state.projectDirectoryURL = source
        state.mutatedProjectDirectoryURL = destination

        _ = try await sut.run(with: state)

        let copiedSources = fileManager.copyPaths.map(\.source)
        let copiedDests = fileManager.copyPaths.map(\.dest)
        let createdDirs = fileManager.paths

        // The whole point of the filtered copy: build artifacts and
        // bookkeeping never make it into the sandbox.
        let excludedFragments = [
            "/.build/",
            "/.swiftpm/",
            "/build/",
            "/DerivedData/",
            "/.git/",
        ]
        for path in copiedSources + createdDirs {
            for fragment in excludedFragments {
                XCTAssertFalse(
                    path.contains(fragment),
                    "Excluded artifact leaked into the copy: \(path)"
                )
            }
        }

        // Everything else is reproduced under the mutated directory.
        XCTAssertTrue(
            copiedSources.contains { $0.hasSuffix("/Package.swift") },
            "Expected top-level Package.swift to be copied, got \(copiedSources)"
        )
        XCTAssertTrue(
            copiedSources.contains { $0.hasSuffix("/Sources/main.swift") },
            "Expected nested Sources/main.swift to be copied, got \(copiedSources)"
        )
        XCTAssertTrue(
            copiedDests.allSatisfy { $0.hasPrefix(destination.path) },
            "Every copied file must land under the mutated directory, got \(copiedDests)"
        )
        XCTAssertEqual(
            copiedDests.first { $0.hasSuffix("/Sources/main.swift") },
            destination.appendingPathComponent("Sources/main.swift").path
        )
        XCTAssertTrue(
            createdDirs.contains(destination.path),
            "Mutated root directory must be created, got \(createdDirs)"
        )
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

    /// Lays down a minimal SwiftPM-shaped project containing the
    /// directories the copy step must skip plus the files it must keep.
    private func makeSourceTree() throws -> URL {
        let manager = FileManager.default
        let root = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        )
        .appendingPathComponent("muter-copy-src-\(UUID().uuidString)")
        sourceRoot = root

        let files = [
            "Package.swift",
            "Sources/main.swift",
            ".build/junk.pcm",
            ".swiftpm/xcode/state",
            "build/output.o",
            "DerivedData/index",
            ".git/config",
        ]

        for file in files {
            let fileURL = root.appendingPathComponent(file)
            try manager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            manager.createFile(atPath: fileURL.path, contents: Data())
        }

        return root
    }
}
