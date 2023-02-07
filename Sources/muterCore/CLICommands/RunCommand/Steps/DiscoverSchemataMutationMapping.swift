import SwiftSyntax
import Foundation

struct DiscoverSchemataMutationMapping: RunCommandStep {
    private let notificationCenter: NotificationCenter = .default
    private let ioDelegate: MutationTestingIODelegate = MutationTestingDelegate()
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        
        notificationCenter.post(
            name: .mutationPointDiscoveryStarted,
            object: nil
        )
        
        let (mutationMappings, sourceCodeByFilePath) = discoverMutationPoints(
            inFilesAt: state.sourceFileCandidates,
            configuration: state.muterConfiguration
        )

        notificationCenter.post(
            name: .mutationPointDiscoveryFinished,
            object: [MutationPoint]()
        )
        
        guard mutationMappings.count >= 1 else {
            return .failure(.noMutationPointsDiscovered)
        }
        
        return .success([
            .mutationMappingsDiscovered(mutationMappings),
            .sourceCodeParsed(sourceCodeByFilePath)
        ])
    }
}

private extension DiscoverSchemataMutationMapping {
    
    func discoverMutationPoints(
        inFilesAt filePaths: [String],
        configuration: MuterConfiguration
    ) -> (
        mappings: [SchemataMutationMapping],
        sourceCodeByFilePath: [FilePath: SourceFileSyntax]
    ) {
        var sourceCodeByFilePath: [FilePath: SourceFileSyntax] = [:]
        let mappings: [SchemataMutationMapping] = filePaths.accumulate(into: []) { alreadyDiscoveredMutationPoints, path in
            
            guard
                pathContainsDotSwift(path),
                let source = addImplicitReturn(path)
            else { return alreadyDiscoveredMutationPoints }
            
            let newSchemataMappings = discoverNewSchemataMappings(
                inFile: SourceCodeInfo(
                    path: path,
                    code: source
                ),
                configuration: configuration
            )
            
            if !newSchemataMappings.isEmpty {
                sourceCodeByFilePath[path] = source
            }
            
            return alreadyDiscoveredMutationPoints + newSchemataMappings
        }
        
        return (
            mappings: mergeSchematasByFileName(mappings),
            sourceCodeByFilePath: sourceCodeByFilePath
        )
    }
    
    func addImplicitReturn(_ filePath: FilePath) -> SourceFileSyntax? {
        guard let source = sourceCode(fromFileAt: filePath)?.code else {
            return nil
        }

        let rewriter = AddImportRewritter().visit(
            ImplicitReturnRewriter().visit(source)
        )
        
        try! ioDelegate.writeFile(
            to: filePath,
            contents: rewriter.description
        )
        
        return sourceCode(fromFileAt: filePath)?.code
    }
    
    private func mergeSchematasByFileName(
        _ mappings: [SchemataMutationMapping]
    ) -> [SchemataMutationMapping] {
        var result = [FileName: SchemataMutationMapping]()

        for map in mappings {
            if let exists = result[map.fileName] {
                result[map.fileName] = exists + map
            } else {
                result[map.fileName] = map
            }
        }
        
        return Array(result.values)
    }
    
    func discoverNewSchemataMappings(
        inFile sourceCodeInfo: SourceCodeInfo,
        configuration: MuterConfiguration
    ) -> [SchemataMutationMapping] {
        let skipMutations = SkipMutations(
            sourceFileInfo: sourceCodeInfo.asSourceFileInfo
        )

        skipMutations.walk(sourceCodeInfo.code)

        return MutationOperator.Id.allCases.accumulate(into: []) { newMutationSchematas, mutationOperatorId in
            
            let visitor = mutationOperatorId.schemataVisitor(
                configuration,
                sourceCodeInfo.asSourceFileInfo
            )

            visitor.walk(sourceCodeInfo.code)

            let schemataMappings = visitor.schemataMappings
            schemataMappings.skipMutations(
                skipMutations.skipPositions
            )
            
            if schemataMappings.isEmpty {
                return newMutationSchematas
            } else {
                return newMutationSchematas + [schemataMappings]
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
                print(node.mutationPosition(with: sourceFileInfo))
                skipPositions.append(
                    node.mutationPosition(with: sourceFileInfo)
                )
            }
        }
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
