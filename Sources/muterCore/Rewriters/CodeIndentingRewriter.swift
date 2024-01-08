import Foundation
import SwiftSyntax

/// Refer from: https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintCore/Rewriters/CodeIndentingRewriter.swift
/// Rewriter that indents or unindents a syntax piece including comments and nested
/// AST nodes (e.g. a code block in a code block).
public class CodeIndentingRewriter: SyntaxRewriter {

    private let style: Indent
    private var isFirstToken = true

    /// Initializer accepting an indentation style.
    ///
    /// - parameter style: Indentation style. The default is indentation by 4 spaces.
    public init(style: Indent = .spaces(4), isFirstToken: Bool = true) {
        self.style = style
        self.isFirstToken = isFirstToken
    }

    override public func visit(_ token: TokenSyntax) -> TokenSyntax {
        defer {
            isFirstToken = false
        }
        return super.visit(
            token.with(\.leadingTrivia, Trivia(pieces: indentedTriviaPieces(for: token.leadingTrivia)))
        )
    }

    private func indentedTriviaPieces(for trivia: Trivia) -> [TriviaPiece] {
        switch style {
        case let .spaces(number): indent(trivia: trivia, by: .spaces(number))
        case let .tabs(number): indent(trivia: trivia, by: .tabs(number))
        }
    }

    private func indent(trivia: Trivia, by indentation: TriviaPiece) -> [TriviaPiece] {
        let indentedPieces = trivia.pieces.flatMap { piece in
            switch piece {
            case .newlines: [piece, indentation]
            default: [piece]
            }
        }
        return isFirstToken ? [indentation] + indentedPieces : indentedPieces
    }
}
