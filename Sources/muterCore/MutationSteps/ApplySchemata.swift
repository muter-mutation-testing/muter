import Foundation
import SwiftFormat

struct ApplySchemata: MutationStep {
    @Dependency(\.writeFile)
    private var writeFile: WriteFile
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        for mutationMap in state.mutationMapping {
            guard let sourceCode = state.sourceCodeByFilePath[mutationMap.filePath] else {
                // TODO: log?
                continue
            }

            let rewriter = MuterRewriter(mutationMap)

            let newFile = rewriter.visit(sourceCode)
            let formattedCode = formatCode(newFile.description)

            do {
                try writeFile(
                    formattedCode,
                    mutationMap.filePath
                )
            } catch {
                throw MuterError.literal(reason: error.localizedDescription)
            }
        }

        return []
    }
}
