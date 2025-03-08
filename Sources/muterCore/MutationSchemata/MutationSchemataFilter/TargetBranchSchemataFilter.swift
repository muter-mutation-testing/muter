//
//  File.swift
//  
//
//  Created by Tuan Hoang on 22/2/25.
//

import Foundation
import SwiftSyntax

protocol MutationSchemataFilter {
    func applyFilter() -> [SchemataMutationMapping]
}

final class TargetBranchSchemataFilter: MutationSchemataFilter {

    private let original: [SchemataMutationMapping]
    private let sourceFileCandidateDiffInfo: [FilePath: FileDiff.Changes]

    init(
        original: [SchemataMutationMapping],
        sourceFileCandidateDiffInfo: [FilePath: FileDiff.Changes]
    ) {
        self.original = original
        self.sourceFileCandidateDiffInfo = sourceFileCandidateDiffInfo
    }

    func applyFilter() -> [SchemataMutationMapping] {
        var results: [SchemataMutationMapping] = []

        for schemata in original {
            guard let diff = sourceFileCandidateDiffInfo[schemata.filePath] else {
                continue
            }

            var newMappings: [CodeBlockItemListSyntax: MutationSchemata] = [:]

            for (key, value) in schemata.mappings {
                let filteredMutationSchematas = value.filter { mutationSchema in
                    switch diff {
                    case .created:
                        return true
                    case .modified(let hunks):
                        return hunks.contains { hunk in
                            let newLineRanges = hunk.newLineStart ..< hunk.newLineStart + hunk.newLineSpan
                            return newLineRanges.contains(mutationSchema.position.line)
                        }
                    case .deleted:
                        return false
                    case .renamed(_, let hunks):
                        return hunks.contains { hunk in
                            let newLineRanges = hunk.newLineStart ..< hunk.newLineStart + hunk.newLineSpan
                            return newLineRanges.contains(mutationSchema.position.line)
                        }
                    }
                }

                if !filteredMutationSchematas.isEmpty {
                    newMappings[key] = filteredMutationSchematas
                }
            }

            if !newMappings.isEmpty {
                results.append(SchemataMutationMapping(filePath: schemata.filePath, mappings: newMappings))
            }
        }

        return results
    }
}
