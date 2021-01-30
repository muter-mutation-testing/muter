import SwiftSyntax
import Foundation

struct DiscoverMutationPoints: RunCommandStep {
    private let notificationCenter: NotificationCenter = .default
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        
        notificationCenter.post(name: .mutationPointDiscoveryStarted, object: nil)
        
        let (mutationPoints, sourceCodeByFilePath) = discoverMutationPoints(inFilesAt: state.sourceFileCandidates, configuration: state.muterConfiguration)
        
        notificationCenter.post(name: .mutationPointDiscoveryFinished, object: mutationPoints)
        
        guard mutationPoints.count >= 1 else {
            return .failure(.noMutationPointsDiscovered)
        }
        
        return .success([.mutationPointsDiscovered(mutationPoints),
                         .sourceCodeParsed(sourceCodeByFilePath)])
    }
}

private extension DiscoverMutationPoints {
    
    func discoverMutationPoints(inFilesAt filePaths: [String], configuration: MuterConfiguration) -> (mutationPoints: [MutationPoint], sourceCodeByFilePath: [FilePath: SourceFileSyntax]) {
        
        var sourceCodeByFilePath: [FilePath: SourceFileSyntax] = [:]
        let mutationPoints: [MutationPoint] = filePaths.accumulate(into: []) { alreadyDiscoveredMutationPoints, path in
            
            guard
                pathContainsDotSwift(path),
                let source = sourceCode(fromFileAt: path)?.code
            else { return alreadyDiscoveredMutationPoints }
            
            let newMutationPoints = discoverNewMutationPoints(inFile: SourceCodeInfo(path: path, code: source), configuration: configuration).sorted(by: filePositionOrder)
            
            if !newMutationPoints.isEmpty {
                sourceCodeByFilePath[path] = source
            }
            
            return alreadyDiscoveredMutationPoints + newMutationPoints
        }
        
        return (
            mutationPoints: mutationPoints,
            sourceCodeByFilePath: sourceCodeByFilePath
        )
    }
    
    func discoverNewMutationPoints(
        inFile sourceCodeInfo: SourceCodeInfo,
        configuration: MuterConfiguration
    ) -> [MutationPoint] {
        let excludedMutationPointsDetector = ExcludedMutationPointsDetector(
            configuration: configuration,
            sourceFileInfo: sourceCodeInfo.asSourceFileInfo
        )

        excludedMutationPointsDetector.walk(sourceCodeInfo.code)

        return MutationOperator.Id.allCases.accumulate(into: []) { newMutationPoints, mutationOperatorId in
            
            let visitor = mutationOperatorId.rewriterVisitorPair.visitor(
                configuration,
                sourceCodeInfo.asSourceFileInfo
            )

            visitor.walk(sourceCodeInfo.code)
            
            return newMutationPoints + visitor.positionsOfToken
                .filter { !excludedMutationPointsDetector.positionsOfToken.contains($0) }
                .map { position in
                    return MutationPoint(mutationOperatorId: mutationOperatorId,
                                         filePath: sourceCodeInfo.path,
                                         position: position)
            }
        }
    }
    
    func filePositionOrder(lhs: MutationPoint, rhs: MutationPoint) -> Bool {
        return lhs.position.line < rhs.position.line &&
            lhs.position.column < rhs.position.column
    }
    
    func pathContainsDotSwift(_ filePath: String) -> Bool {
        let url = URL(fileURLWithPath: filePath)
        return url.lastPathComponent.contains(".swift")
    }
}

// Currently supports only line comments (in block comments, would need to detect in which actual line the skip marker appears - and if it isn't the first or last line, it won't contain code anyway)
private class ExcludedMutationPointsDetector: SyntaxAnyVisitor, PositionDiscoveringVisitor {
    var positionsOfToken: [MutationPosition] = []
    
    private let muterSkipMarker = "muter:skip"
    
    private let sourceFileInfo: SourceFileInfo
    
    init(configuration: MuterConfiguration?, sourceFileInfo: SourceFileInfo) {
        self.sourceFileInfo = sourceFileInfo
    }
    
    override func visitAnyPost(_ node: Syntax) {
        node.leadingTrivia.map { leadingTrivia in
            if leadingTrivia.containsLineComment(muterSkipMarker) {
                positionsOfToken.append(
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
