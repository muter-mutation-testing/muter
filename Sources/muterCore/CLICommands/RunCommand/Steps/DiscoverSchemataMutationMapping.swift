import SwiftSyntax
import Foundation

struct DiscoverSchemataMutationMapping: RunCommandStep {
    private let notificationCenter: NotificationCenter = .default
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        
        notificationCenter.post(name: .mutationPointDiscoveryStarted, object: nil)
        
        let mutationPoints = discoverMutationPoints(inFilesAt: state.sourceFileCandidates, configuration: state.muterConfiguration)
        
        notificationCenter.post(name: .mutationPointDiscoveryFinished, object: mutationPoints)
        
        guard mutationPoints.count >= 1 else {
            return .failure(.noMutationPointsDiscovered)
        }
        
        return .success([
            .mutationMappingsDiscovered(mutationPoints)
        ])
    }
}

private extension DiscoverSchemataMutationMapping {
    
    func discoverMutationPoints(
        inFilesAt filePaths: [String],
        configuration: MuterConfiguration
    ) -> [SchemataMutationMapping] {
        let mutationPoints: [SchemataMutationMapping] = filePaths.accumulate(into: []) { alreadyDiscoveredMutationPoints, path in
            
            guard
                pathContainsDotSwift(path),
                let source = sourceCode(fromFileAt: path)?.code
            else { return alreadyDiscoveredMutationPoints }
            
            let newMutationPoints = discoverNewMutationPoints(
                inFile: SourceCodeInfo(path: path, code: source),
                configuration: configuration
            )
            
            return alreadyDiscoveredMutationPoints + newMutationPoints
        }
        
        return mutationPoints
    }
    
    func discoverNewMutationPoints(
        inFile sourceCodeInfo: SourceCodeInfo,
        configuration: MuterConfiguration
    ) -> [SchemataMutationMapping] {
        let excludedMutationPoints = ExcludedMutationPoints(
            sourceFileInfo: sourceCodeInfo.asSourceFileInfo
        )

        excludedMutationPoints.walk(sourceCodeInfo.code)

        return MutationOperator.Id.allCases.accumulate(into: []) { newMutationSchematas, mutationOperatorId in
            
            let visitor = mutationOperatorId.schemataVisitor(
                configuration,
                sourceCodeInfo.asSourceFileInfo
            )

            visitor.walk(sourceCodeInfo.code)

            let schemataMappings = visitor.schemataMappings
            schemataMappings.excludePoints(excludedMutationPoints.excludedPositions)
            
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
private class ExcludedMutationPoints: SyntaxAnyVisitor {
    private(set) var excludedPositions: [MutationPosition] = []
    
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
                excludedPositions.append(
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
