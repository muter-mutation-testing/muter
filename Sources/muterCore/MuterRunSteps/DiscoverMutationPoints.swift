import Foundation
import SwiftSyntax

struct DiscoverMutationPoints: RunCommandStep {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.prepareCode)
    var prepareSourceCode: SourceCodePreparation

    func run(
        with state: AnyRunCommandState
    ) async throws -> [RunCommandState.Change] {
        notificationCenter.post(
            name: .mutationsDiscoveryStarted,
            object: nil
        )

        let discovered = discoverMutationPoints(
            forOperators: state.mutationOperatorList,
            inFilesAt: state.sourceFileCandidates,
            configuration: state.muterConfiguration
        )

        guard discovered.mappings.count >= 1 else {
            throw MuterError.noMutationPointsDiscovered
        }

        let mappings = discovered.mappings.mergeByFileName()

        notificationCenter.post(
            name: .mutationsDiscoveryFinished,
            object: mappings
        )

        return [
            .mutationMappingsDiscovered(mappings),
            .sourceCodeParsed(discovered.sourceCodeByFilePath)
        ]
    }
}

private extension DiscoverMutationPoints {

    func discoverMutationPoints(
        forOperators operators: MutationOperatorList,
        inFilesAt filePaths: [String],
        configuration: MuterConfiguration
    ) -> DiscoveredFiles {
        filePaths.accumulate(into: DiscoveredFiles()) { discoveredFiles, path in
            guard
                pathContainsDotSwift(path),
                let sourceCode = prepareSourceCode(path)
            else {
                return discoveredFiles
            }

            let schemataMappings = discoverNewSchemataMappings(
                forOperators: operators,
                inFile: sourceCode,
                configuration: configuration
            )

            if !schemataMappings.isEmpty {
                discoveredFiles.sourceCodeByFilePath[path] = sourceCode.source.code
            }

            discoveredFiles.mappings.append(contentsOf: schemataMappings)

            return discoveredFiles
        }
    }

    func discoverNewSchemataMappings(
        forOperators operators: MutationOperatorList,
        inFile sourceCode: PreparedSourceCode,
        configuration: MuterConfiguration
    ) -> [SchemataMutationMapping] {
        let source = sourceCode.source.code

        return operators.accumulate(into: []) { newSchemataMappings, mutationOperatorId in
            let visitor = mutationOperatorId.visitor(
                configuration,
                sourceCode.source
            )

            visitor.sourceCodePreparationChange = sourceCode.changes

            visitor.walk(source)

            let schemataMapping = visitor.schemataMappings

            if !schemataMapping.isEmpty {
                return newSchemataMappings + [schemataMapping]
            } else {
                return newSchemataMappings
            }
        }
    }

    func pathContainsDotSwift(_ filePath: String) -> Bool {
        let url = URL(fileURLWithPath: filePath)
        return url.lastPathComponent.contains(".swift")
    }
}

private class DiscoveredFiles {
    var mappings: [SchemataMutationMapping] = []
    var sourceCodeByFilePath: [FilePath: SourceFileSyntax] = [:]
}
