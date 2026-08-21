import Foundation

class CopyProjectToTempDirectory: MutationStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.process)
    private var process: ProcessFactory

    private let moduleCacheDirectoryName = "ModuleCache"

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        do {
            notificationCenter.post(
                name: .projectCopyStarted,
                object: nil
            )

            try fileManager.copyItem(
                atPath: state.projectDirectoryURL.path,
                toPath: state.mutatedProjectDirectoryURL.path
            )

            discardModuleCaches(in: state.mutatedProjectDirectoryURL)

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

    /// Clang module caches record the absolute path they were built under. Copied alongside the rest of
    /// a project's build directory they no longer match where they now live, and every compile in the
    /// copy fails with `precompiled file … was compiled with module cache path …` followed by
    /// `missing required module 'SwiftShims'`. Discarding them keeps the rest of the build directory
    /// warm — the compiler rebuilds the caches in place on the next compile.
    private func discardModuleCaches(in directory: URL) {
        let caches = process()
            .find(atPath: directory.path, byName: moduleCacheDirectoryName)?
            .split(separator: "\n")
            .map(String.init) ?? []

        for cache in caches {
            try? fileManager.removeItem(atPath: cache)
        }
    }
}
