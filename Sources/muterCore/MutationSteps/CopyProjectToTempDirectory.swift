import Foundation

class CopyProjectToTempDirectory: MutationStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter

    /// Directory names that must NOT be carried into the mutated copy:
    ///   - `.build`, `build`, `DerivedData`: build outputs whose
    ///     precompiled module caches embed absolute paths from the
    ///     original project root and break compilation in the copy.
    ///   - `.swiftpm`: per-workspace SwiftPM state that points at the
    ///     original project; SwiftPM regenerates it inside the copy.
    ///   - `.git`: muter does not need the working-tree's git metadata,
    ///     and pulling it along increases copy cost noticeably on
    ///     long-lived repos.
    /// `Package.resolved` is preserved at the top level so the copy
    /// resolves to identical dependency versions without going to the
    /// network.
    private static let excludedDirectoryNames: Set<String> = [
        ".build",
        ".swiftpm",
        "build",
        "DerivedData",
        ".git",
    ]

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        do {
            notificationCenter.post(
                name: .projectCopyStarted,
                object: nil
            )

            try copyProjectFiltered(
                from: state.projectDirectoryURL,
                to: state.mutatedProjectDirectoryURL
            )

            notificationCenter.post(
                name: .projectCopyFinished,
                object: state.mutatedProjectDirectoryURL.path
            )

            return []
        } catch {
            throw MuterError.projectCopyFailed(
                reason: error.localizedDescription
            )
        }
    }

    /// Walks `source` and reproduces it under `destination`, omitting
    /// the well-known build-artifact directories listed in
    /// `excludedDirectoryNames`. Equivalent to
    /// `FileManager.copyItem(atPath:toPath:)` on the relevant payload
    /// but a) avoids the stale-path / re-extraction failure modes of
    /// copying `.build`, b) skips git/swiftpm bookkeeping that the
    /// sandbox doesn't need.
    ///
    /// Uses `FileManager.default.enumerator` directly because the
    /// `FileSystemManager` protocol does not surface enumerator-based
    /// traversal; the actual create / copy operations still go through
    /// the injected `fileManager` so they remain mockable in tests.
    private func copyProjectFiltered(
        from source: URL,
        to destination: URL
    ) throws {
        try fileManager.createDirectory(
            atPath: destination.path,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let raw = FileManager.default
        guard let enumerator = raw.enumerator(
            at: source,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [],
            errorHandler: nil
        ) else {
            throw NSError(
                domain: "Muter.CopyProjectToTempDirectory",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not enumerate source: \(source.path)"]
            )
        }

        let sourceRoot = source.standardizedFileURL.path
        while let url = enumerator.nextObject() as? URL {
            // Drop the entire subtree rooted at any excluded directory.
            if Self.excludedDirectoryNames.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }

            let isDirectory: Bool = {
                guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey]) else {
                    return false
                }
                return values.isDirectory ?? false
            }()

            // Build the destination path by replacing the source-root
            // prefix; this preserves the relative tree under `destination`.
            let absolute = url.standardizedFileURL.path
            guard absolute.hasPrefix(sourceRoot + "/") else { continue }
            let relative = String(absolute.dropFirst(sourceRoot.count + 1))
            let target = destination.appendingPathComponent(relative).path

            if isDirectory {
                try fileManager.createDirectory(
                    atPath: target,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } else {
                try fileManager.copyItem(
                    atPath: url.path,
                    toPath: target
                )
            }
        }
    }
}
