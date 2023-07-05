import Foundation
import SwiftSyntax
import SwiftParser

public final class Visitor: SyntaxAnyVisitor {
    private(set) var highlightedCode: String = ""
    private(set) var themes: [TokenKind: (String) -> String]
    private(set) var commentsTransformer: (String) -> String

    public init(theme: Theme) {
        self.commentsTransformer = theme.commentsTransformer
        self.themes = theme.transformer.reduce(into: [:]) { partialResult, tokensAndTransformer in
            for token in tokensAndTransformer.key {
                partialResult[token] = tokensAndTransformer.value
            }
        }
        
        super.init(viewMode: .all)
    }
    
    public override func visit(_ tokenSyntax: TokenSyntax) -> SyntaxVisitorContinueKind {
        let node = tokenSyntax
            .trasformingLeavingTrivia(highlightComments)
            .trasformingTrailingTrivia(highlightComments)
        
        highlightedCode += themes[node.tokenKind]?(node.description) ?? node.description
        
        return super.visit(node)
    }
    
    private func highlightComments(_ trivia: Trivia) -> Trivia {
        var pieces: [TriviaPiece] = []
        
        for piece in trivia.pieces {
            switch piece {
            case .lineComment(let comment):
                pieces.append(.lineComment(commentsTransformer(comment)))
            case .blockComment(let comment):
                pieces.append(.blockComment(commentsTransformer(comment)))
            case .docLineComment(let comment):
                pieces.append(.docLineComment(commentsTransformer(comment)))
            case .docBlockComment(let comment):
                pieces.append(.docBlockComment(commentsTransformer(comment)))
            default:
                pieces.append(piece)
            }
        }
        
        return Trivia(pieces: pieces)
    }
}

public extension Visitor {
    static func highlightCode(
        _ code: String,
        theme: Theme
    ) -> String {
        let parser = Parser.parse(source: code)
        let visitor = Visitor(theme: theme)
        
        visitor.walk(parser)
        
        return visitor.highlightedCode
    }
}

extension SyntaxProtocol {
    func trasformingLeavingTrivia(_ builder: (Trivia) -> Trivia) -> Self {
        leadingTrivia.flatMap {
            withLeadingTrivia(builder($0))
        } ?? self
    }
    
    func trasformingTrailingTrivia(_ builder: (Trivia) -> Trivia) -> Self {
        trailingTrivia.flatMap {
            withTrailingTrivia(builder($0))
        } ?? self
    }
}

extension Trivia {
    var hasComments: Bool {
        for p in pieces {
            switch p {
            case .lineComment:
                return true
            default:
                continue
            }
        }
        
        return false
    }
}
