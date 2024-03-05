import Foundation

struct GenerateSwapFilePaths: MutationStep {
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        let result = createSwapFileDirectory(in: state.mutatedProjectDirectoryURL.path)

        switch result {
        case let .success(swapFileDirectoryPath):

            let filePaths = state.sourceCodeByFilePath.keys.map { String($0) }
            let swapFilePathsByOriginalPath = swapFilePaths(
                forFilesAt: filePaths,
                using: swapFileDirectoryPath
            )

            return [.swapFilePathGenerated(swapFilePathsByOriginalPath)]

        case let .failure(error):
            throw MuterError.unableToCreateSwapFileDirectory(reason: error.localizedDescription)
        }
    }
}

private extension GenerateSwapFilePaths {
    func createSwapFileDirectory(in directory: FilePath) -> Result<FilePath, Error> {
        do {
            let swapFileDirectory = "\(directory)/muter_tmp"
            try fileManager.createDirectory(
                atPath: swapFileDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            return .success(swapFileDirectory)
        } catch {
            return .failure(error)
        }
    }
}

extension GenerateSwapFilePaths { // this is internal to simplify testing

    func swapFilePaths(
        forFilesAt paths: [FilePath],
        using workingDirectoryPath: FilePath
    ) -> [FilePath: FilePath] {
        var swapFilePathsByOriginalPath: [FilePath: FilePath] = [:]

        for path in paths {
            swapFilePathsByOriginalPath[path] = swapFilePath(forFileAt: path, using: workingDirectoryPath)
        }

        return swapFilePathsByOriginalPath
    }

    func swapFilePath(forFileAt path: FilePath, using workingDirectory: FilePath) -> String {
        let url = URL(fileURLWithPath: path)
        return "\(workingDirectory)/\(url.lastPathComponent)"
    }
}
