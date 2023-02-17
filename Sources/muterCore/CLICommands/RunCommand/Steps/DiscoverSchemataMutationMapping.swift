import SwiftSyntax
import Foundation

struct DiscoverSchemataMutationMapping: RunCommandStep {
    private let notificationCenter: NotificationCenter = .default
    var prepareSourceCode: (String) -> PreparedSourceCode? = muterCore.prepareSourceCode

    func run(
        with state: AnyRunCommandState
    ) -> Result<[RunCommandState.Change], MuterError> {
        
        notificationCenter.post(
            name: .mutationsDiscoveryStarted,
            object: nil
        )
        
        let discovered = discoverMutationPoints(
            inFilesAt: state.sourceFileCandidates,
            configuration: state.muterConfiguration
        )
        
        guard discovered.mappings.count >= 1 else {
            return .failure(.noMutationPointsDiscovered)
        }
       
        let mappings = discovered.mappings.mergeByFileName()

        notificationCenter.post(
            name: .mutationsDiscoveryFinished,
            object: mappings
        )
        
        return .success([
            .mutationMappingsDiscovered(mappings),
            .sourceCodeParsed(discovered.sourceCodeByFilePath)
        ])
    }
}

private extension DiscoverSchemataMutationMapping {
    
    func discoverMutationPoints(
        inFilesAt filePaths: [String],
        configuration: MuterConfiguration
    ) -> DiscoveredFiles {
        return filePaths.accumulate(into: DiscoveredFiles()) { discoveredFiles, path in
            guard
                pathContainsDotSwift(path),
                let sourceCode = prepareSourceCode(path)
            else { return discoveredFiles }
            
            let schemataMappings = discoverNewSchemataMappings(
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
        inFile sourceCode: PreparedSourceCode,
        configuration: MuterConfiguration
    ) -> [SchemataMutationMapping] {
        let source = sourceCode.source.code
        let sourceFileInfo = sourceCode.source.asSourceFileInfo
        let skipMutations = SkipMutations(
            sourceFileInfo: sourceFileInfo
        )
        
        skipMutations.walk(source)

        return MutationOperator.Id.allCases.accumulate(into: []) { newSchemataMappings, mutationOperatorId in
            let visitor = mutationOperatorId.schemataVisitor(
                configuration,
                sourceFileInfo
            )
            
            visitor.walk(source)

            let schemataMapping = visitor
                .schemataMappings
                .skipMutations(skipMutations.skipPositions)
            
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

// Currently supports only line comments (in block comments, would need to detect in which actual line the skip marker appears - and if it isn't the first or last line, it won't contain code anyway)
private class SkipMutations: SyntaxAnyVisitor {
    private(set) var skipPositions: [MutationPosition] = []
    
    private let muterSkipMarker = "muter:skip"
    
    private let sourceFileInfo: SourceFileInfo
    
    required init(
        sourceFileInfo: SourceFileInfo
    ) {
        self.sourceFileInfo = sourceFileInfo
    }

    override func visitAnyPost(_ node: Syntax) {
        node.leadingTrivia.map { leadingTrivia in
            if leadingTrivia.containsLineComment(muterSkipMarker) {
                skipPositions.append(
                    mutationPosition(for: node)
                )
            }
        }
    }
    
    func mutationPosition(for node: Syntax) -> MutationPosition {
        let converter = SourceLocationConverter(
            file: sourceFileInfo.path,
            source: sourceFileInfo.source
        )

        let sourceLocation = SourceLocation(
            offset: node.position.utf8Offset,
            converter: converter
        )

        return MutationPosition(
            sourceLocation: sourceLocation
        )
    }
}

private extension SwiftSyntax.Trivia {
    func containsLineComment(_ comment: String) -> Bool {
        return contains { piece in
            if case .lineComment(let commentText) = piece {
                return commentText.contains(comment)
            } else {
                return false
            }
        }
    }
}

private class DiscoveredFiles {
    var mappings: [SchemataMutationMapping] = []
    var sourceCodeByFilePath: [FilePath: SourceFileSyntax] = [:]
}

typealias PreparedSourceCode = (
    source: SourceCodeInfo,
    changes: MutationSourceCodePreparationChange
)

func prepareSourceCode(
    _ path: String
) -> PreparedSourceCode? {
    guard let source = sourceCode(fromFileAt: path) else {
        return nil
    }

    let addImport = AddImportRewriter()
    let addImportSource = addImport.visit(source.code)
    
    let disableLinters = DisableLintersRewriter()
    let disableLintersSource = disableLinters.visit(addImportSource)
    
    let filePath = source.path
    let newSourceCode = disableLintersSource.description
    
    let numberOfNewLines = addImport.newLinesAddedToFile + disableLinters.newLinesAddedToFile
    let changes = MutationSourceCodePreparationChange(
        newLines: numberOfNewLines
    )

    do {
        try newSourceCode.write(
            toFile: filePath,
            atomically: true,
            encoding: .utf8
        )
        
        return sourceCode(fromFileAt: filePath)
            .map { sourceCode in
                return (source: sourceCode, changes: changes)
            }
    } catch {
        return nil
    }
}
