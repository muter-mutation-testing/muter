import SwiftSyntax
import Foundation

struct DiscoverMutationPoints: RunCommandStep {
    private let notificationCenter: NotificationCenter = .default
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        
        notificationCenter.post(name: .mutationPointDiscoveryStarted, object: nil)

        let (mutationPoints, sourceCodeByFilePath) = discoverMutationPoints(inFilesAt: state.sourceFileCandidates)
        
        notificationCenter.post(name: .mutationPointDiscoveryFinished, object: mutationPoints)
        
        guard mutationPoints.count >= 1 else {
            return .failure(.noMutationPointsDiscovered)
        }
        
        return .success([.mutationPointsDiscovered(mutationPoints),
                         .sourceCodeParsed(sourceCodeByFilePath)])
    }
}

private extension DiscoverMutationPoints {
    
    func discoverMutationPoints(inFilesAt filePaths: [String]) -> (mutationPoints: [MutationPoint], sourceCodeByFilePath: [FilePath: SourceFileSyntax]) {
        
        var sourceCodeByFilePath: [FilePath: SourceFileSyntax] = [:]
        let excludedMutationPoints = loadMutationPointsToExclude(inFilesAt: filePaths)

        let mutationPoints: [MutationPoint] = filePaths.accumulate(into: []) { alreadyDiscoveredMutationPoints, path in
            
            guard pathContainsDotSwift(path),
                let source = sourceCode(fromFileAt: path) else {
                    return alreadyDiscoveredMutationPoints
            }

            let newMutationPoints = discoverNewMutationPoints(inFileAt: path, containing: source)
                .filter { !excludedMutationPoints.contains(where: $0.matchesByLine) }
                .sorted(by: filePositionOrder)
            
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
    
    func discoverNewMutationPoints(inFileAt path: String, containing source: SourceFileSyntax) -> [MutationPoint] {
        return MutationOperator.Id.allCases.accumulate(into: []) { newMutationPoints, mutationOperatorId in
            
            let visitor = mutationOperatorId.rewriterVisitorPair.visitor()
            visitor.visit(source)
            
            return newMutationPoints + visitor.positionsOfToken.map { position in
                return MutationPoint(mutationOperatorId: mutationOperatorId,
                                     filePath: path,
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
