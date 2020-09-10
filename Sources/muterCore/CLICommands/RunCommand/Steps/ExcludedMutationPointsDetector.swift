import Foundation
import SwiftSyntax

// Currently supports only line comments (in block comments, would need to detect in which actual line the skip marker appears - and if it isn't the first or last line, it won't contain code anyway)
final class ExcludedMutationPointsDetector: SyntaxAnyVisitor, PositionDiscoveringVisitor {
    var positionsOfToken: [MutationPosition] = []
    
    private let muterSkipMarker = "muter:skip"
    
    private let file: String
    private let source: String
    
    init(configuration: MuterConfiguration?, file: String, source: String) {
        self.file = file
        self.source = source
    }
    
    override func visitAnyPost(_ node: Syntax) {
        node.leadingTrivia.map { leadingTrivia in
            if leadingTrivia.containsLineComment(muterSkipMarker) {
                positionsOfToken.append(
                    node.mutationPosition(inFile: file, withSource: source)
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
