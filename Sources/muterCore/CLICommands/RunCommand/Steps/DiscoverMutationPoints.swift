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
            
            guard pathContainsDotSwift(path),
                  let source = sourceCode(fromFileAt: path)?.code else {
                    return alreadyDiscoveredMutationPoints
            }
            
            let newMutationPoints = discoverNewMutationPoints(inFileAt: path, containing: source, configuration: configuration).sorted(by: filePositionOrder)
            
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
    
    func discoverNewMutationPoints(inFileAt path: String, containing source: SourceFileSyntax, configuration: MuterConfiguration) -> [MutationPoint] {

        let excludedMutationPointsDetector = ExcludedMutationPointsDetector()
        _ = excludedMutationPointsDetector.visit(source)

        return MutationOperator.Id.allCases.accumulate(into: []) { newMutationPoints, mutationOperatorId in
            
            var visitor = mutationOperatorId.rewriterVisitorPair.visitor(configuration, path, source.description)
            visitor.file = path
            visitor.source = source.description

            visitor.walk(source)
            
            return newMutationPoints + visitor.positionsOfToken
                .filter { !excludedMutationPointsDetector.excludedUTF8Offsets.contains($0.line) }
                .map { position in
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
