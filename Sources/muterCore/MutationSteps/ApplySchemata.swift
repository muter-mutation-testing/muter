import Foundation
import SwiftParser
import SwiftSyntax

struct ApplySchemata: MutationStep {
    @Dependency(\.writeFile)
    private var writeFile: WriteFile
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        for mutationMap in state.mutationMapping {
            // Try cached source code first, fall back to re-parsing
            // Re-parsing on demand prevents memory exhaustion on large codebases
            let sourceCode: SourceFileSyntax
            if let cached = state.sourceCodeByFilePath[mutationMap.filePath] {
                sourceCode = cached
            } else if let parsed = loadSourceCode(from: mutationMap.filePath) {
                sourceCode = parsed
            } else {
                continue
            }

            let rewriter = MuterRewriter(mutationMap)

            let newFile = rewriter.visit(sourceCode)

            do {
                try writeFile(
                    newFile.description,
                    mutationMap.filePath
                )
            } catch {
                throw MuterError.literal(reason: error.localizedDescription)
            }
        }

        return []
    }

    private func loadSourceCode(from path: String) -> SourceFileSyntax? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let source = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return Parser.parse(source: source)
    }
}
