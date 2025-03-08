//
//  File.swift
//
//
//  Created by Tuan Hoang on 8/3/25.
//

import Foundation

struct SourceBranchFilter {

    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager

    @Dependency(\.process)
    var process: ProcessFactory

    func filterChangedFilesIfNeed(state: AnyMutationTestState, sourceFileCandidates: [FilePath]) -> [FilePath] {
        let currentWorkingDirectory = fileManager.currentDirectoryPath
        fileManager.changeCurrentDirectoryPath(state.mutatedProjectDirectoryURL.path)

        guard let sourceBranch = state.runOptions.sourceBranch else {
            return sourceFileCandidates
        }
        var results: [FilePath] = []

        for file in sourceFileCandidates {
            if let diffChange = getFileDiffChange(sourceBranch: sourceBranch, sourceFile: file) {
                switch diffChange {
                case .created, .modified:
                    results.append(file)
                case .deleted:
                    continue
                case .renamed(_, let hunks):
                    if !hunks.isEmpty {
                        results.append(file)
                    }
                }

                state.sourceFileCandidateChangedInfo[file] = diffChange
            }
        }

        fileManager.changeCurrentDirectoryPath(currentWorkingDirectory)
        return results
    }

    private func getFileDiffChange(
        sourceBranch: String,
        sourceFile: FilePath
    ) -> FileDiff.Changes? {
        do {
            let changes: FileDiff.Changes = try diff(forFile: sourceFile, sourceBranch: sourceBranch)
                .get()
                .changes

            return changes
        } catch {
            return nil
        }
    }

    private func diff(forFile file: String, sourceBranch: String) -> Result<FileDiff, Error> {
        let parser = DiffParser()
        let diff = Result {
            process().runProcess(
                url: process().which("git") ?? "",
                arguments: [
                    "diff",
                    sourceBranch,
                    "--",
                    file
                ]
            )
            .flatMap(\.nilIfEmpty)
            .map(\.trimmed)
        }

        return diff.flatMap {
            guard let diff = $0 else {
                return .failure(DiffError.invalidDiff)
            }
            let parsedDiff = parser.parse(diff)

            if let fileDiff = parsedDiff.first {
                return .success(fileDiff)
            } else {
                return .failure(DiffError.invalidDiff)
            }
        }
    }
}
