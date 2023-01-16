import SwiftSyntax
import Foundation

struct _MutationPoint: Equatable {
    let filePath: FilePath
    let fileSource: SourceFileSyntax
    let schematas: [Schemata]
}

extension _MutationPoint: Nullable {
    static var null: _MutationPoint {
        _MutationPoint(
            filePath: "",
            fileSource: SyntaxFactory.makeBlankSourceFile(),
            schematas: []
        )
    }
}

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
                         .sourceCodeParsed(sourceCodeByFilePath),])
    }
}

private extension DiscoverMutationPoints {
    
    func discoverMutationPoints(
        inFilesAt filePaths: [String],
        configuration: MuterConfiguration
    ) -> (mutationPoints: [_MutationPoint], sourceCodeByFilePath: [FilePath: SourceFileSyntax]) {
        
        var sourceCodeByFilePath: [FilePath: SourceFileSyntax] = [:]
        let mutationPoints: [_MutationPoint] = filePaths.accumulate(into: []) { alreadyDiscoveredMutationPoints, path in
            
            guard
                pathContainsDotSwift(path),
                let source = sourceCode(fromFileAt: path)?.code
            else { return alreadyDiscoveredMutationPoints }
            
            let newMutationPoints = discoverNewMutationPoints(
                inFile: SourceCodeInfo(path: path, code: source),
                configuration: configuration
            )//.sorted(by: filePositionOrder)
            
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
    ) -> [_MutationPoint] {
        let excludedMutationPointsDetector = ExcludedMutationPointsDetector(
            sourceFileInfo: sourceCodeInfo.asSourceFileInfo
        )

        excludedMutationPointsDetector.walk(sourceCodeInfo.code)

        return MutationOperator.Id.allCases.accumulate(into: []) { newMutationPoints, mutationOperatorId in
            
            let visitor = mutationOperatorId.rewriterVisitorPair.visitor(
                configuration,
                sourceCodeInfo.asSourceFileInfo
            )

            visitor.walk(sourceCodeInfo.code)

            let schematas = visitor.schematas.excludeTokenAtPositions(excludedMutationPointsDetector.positionsOfToken)
            let rewritten = Rewriter(schematas).visit(sourceCodeInfo.code)
            guard let mutatedSource = SourceFileSyntax(rewritten) else {
                // TODO: fatalError or just log
                return newMutationPoints
            }

            let fileSchematas: [Schemata] = schematas.accumulate(into: []) { newSchematas, schematas  in
                return newSchematas + schematas.value
            }

            return newMutationPoints + [
                _MutationPoint(
                    filePath: sourceCodeInfo.path,
                    fileSource: mutatedSource,
                    schematas: fileSchematas
                )
            ]
        }
    }
    
//    func filePositionOrder(lhs: MutationPoint, rhs: MutationPoint) -> Bool {
//        return lhs.position.line < rhs.position.line &&
//            lhs.position.column < rhs.position.column
//    }
    
    func pathContainsDotSwift(_ filePath: String) -> Bool {
        let url = URL(fileURLWithPath: filePath)
        return url.lastPathComponent.contains(".swift")
    }
}

extension Dictionary where Key == CodeBlockItemListSyntax, Value == [Schemata] {
    func excludeTokenAtPositions(_ positions: [MutationPosition]) -> Self {
        // mapValues
        var result = self
        for (key, value) in self {
            result[key] = value.exclude { positions.contains($0.positionInSourceCode) }
        }

        return result
    }
}

// Currently supports only line comments (in block comments, would need to detect in which actual line the skip marker appears - and if it isn't the first or last line, it won't contain code anyway)
private class ExcludedMutationPointsDetector: SyntaxAnyVisitor {
    private(set) var positionsOfToken: [MutationPosition] = []
    
    private let muterSkipMarker = "muter:skip"
    
    private let sourceFileInfo: SourceFileInfo
    
    required init(sourceFileInfo: SourceFileInfo) {
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
            }

            return false
        }
    }
}

class Rewriter: SyntaxRewriter {
    private let schematas: [CodeBlockItemListSyntax: [Schemata]]

    required init(_ schematas: [CodeBlockItemListSyntax: [Schemata]]) {
        self.schematas = schematas
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> Syntax {
        guard let mutationsInNode = schematas[node] else {
            return super.visit(node)
        }

        let newNode = applyMutationSwitch(
            withOriginalSyntax: node,
            and: mutationsInNode.map { ($0.id, $0.syntaxMutation) }
        )

        return super.visit(newNode)
    }
}
