import Foundation
import SwiftSyntax

struct DiscoverMutationPoints: MutationStep {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.prepareCode)
    var prepareSourceCode: SourceCodePreparation

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        notificationCenter.post(
            name: .mutationsDiscoveryStarted,
            object: nil
        )

        let discovered = discoverMutationPoints(
            forOperators: state.mutationOperatorList,
            inFilesAt: state.sourceFileCandidates,
            configuration: state.muterConfiguration,
            coverage: state.projectCoverage
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
            // Only files that actually produced mutations are cached, so
            // ApplySchemata rewrites the *same* parse tree the mapping keys
            // belong to. Non-mutated files' ASTs are freed during the scan
            // (autoreleasepool below), keeping memory bounded on large
            // codebases without silently dropping every mutation.
            .sourceCodeParsed(discovered.sourceCodeByFilePath),
        ]
    }
}

private extension DiscoverMutationPoints {

    // Batch size for parallel processing - balances memory usage vs. parallelism
    static let batchSize = 50
    // Max concurrent tasks to limit memory pressure
    static let maxConcurrency = 8

    func discoverMutationPoints(
        forOperators operators: MutationOperatorList,
        inFilesAt filePaths: [String],
        configuration: MuterConfiguration,
        coverage: Coverage
    ) -> DiscoveredFiles {
        // Process files in parallel batches for better performance on large codebases
        // Uses autoreleasepool per file to prevent memory accumulation
        let discoveredFiles = DiscoveredFiles()
        let swiftFiles = filePaths.filter(pathContainsDotSwift)

        // Process in batches to limit memory pressure
        let batches = swiftFiles.chunked(into: Self.batchSize)

        for batch in batches {
            // Process batch concurrently using DispatchGroup
            let group = DispatchGroup()
            let queue = DispatchQueue(label: "muter.discovery", attributes: .concurrent)
            let semaphore = DispatchSemaphore(value: Self.maxConcurrency)
            let lock = NSLock()

            for path in batch {
                group.enter()
                semaphore.wait()

                queue.async {
                    defer {
                        semaphore.signal()
                        group.leave()
                    }

                    autoreleasepool {
                        guard let sourceCode = self.prepareSourceCode(path) else {
                            return
                        }

                        let schemataMappings = self.discoverNewSchemataMappings(
                            forOperators: operators,
                            inFile: sourceCode,
                            configuration: configuration,
                            regionsWithoutCoverage: coverage.regionsForFile(path)
                        )

                        if !schemataMappings.isEmpty {
                            lock.lock()
                            discoveredFiles.mappings.append(contentsOf: schemataMappings)
                            discoveredFiles.sourceCodeByFilePath[path] = sourceCode.source.code
                            lock.unlock()
                        }
                    }
                }
            }

            group.wait()
        }

        return discoveredFiles
    }

    func discoverNewSchemataMappings(
        forOperators operators: MutationOperatorList,
        inFile sourceCode: PreparedSourceCode,
        configuration: MuterConfiguration,
        regionsWithoutCoverage: [Region]
    ) -> [SchemataMutationMapping] {
        let source = sourceCode.source.code

        return operators.accumulate(into: []) { newSchemataMappings, mutationOperatorId in
            let visitor = mutationOperatorId.visitor(
                configuration,
                sourceCode.source,
                regionsWithoutCoverage
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
