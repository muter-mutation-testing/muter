import SwiftSyntax

extension SyntaxProtocol {
    var scapedDescription: String {
        description.replacingOccurrences(
            of: "\n",
            with: "\\n"
        )
        .replacingOccurrences(
            of: "\"",
            with: "\\\""
        )
    }

    var codeBlockItemListSyntax: CodeBlockItemListSyntax {
        let syntax = Syntax(self)
        if syntax.is(CodeBlockItemListSyntax.self) {
            return syntax.as(CodeBlockItemListSyntax.self)!
        }

        var parent = parent

        while parent?.is(CodeBlockItemListSyntax.self) == false {
            parent = parent?.parent
        }

        return parent!.as(CodeBlockItemListSyntax.self)!
    }

    func appendingLeadingTrivia(
        _ pieces: TriviaPiece...
    ) -> Self {
        if var trivia = leadingTrivia {
            pieces.forEach { trivia = trivia.appending($0) }

            return withLeadingTrivia(trivia)
        } else {
            return withLeadingTrivia(Trivia(pieces: pieces))
        }
    }

    func appendingTrailingTrivia(
        _ pieces: TriviaPiece...
    ) -> Self {
        if var trivia = trailingTrivia {
            pieces.forEach { trivia = trivia.appending($0) }

            return withTrailingTrivia(trivia)
        } else {
            return withTrailingTrivia(Trivia(pieces: pieces))
        }
    }

    func withTrailingTrivia(
        _ trivia: Trivia?
    ) -> Self {
        if let trivia {
            return withTrailingTrivia(trivia)
        } else {
            return self
        }
    }

    func withLeadingTrivia(
        _ trivia: Trivia?
    ) -> Self {
        if let trivia {
            return withLeadingTrivia(trivia)
        } else {
            return self
        }
    }

    var allChildren: SyntaxChildren {
        children(viewMode: .all)
    }

    func containsLineComment(_ comment: String) -> Bool {
        leadingTrivia.containsLineComment(comment)
            || trailingTrivia.containsLineComment(comment)
    }
}

extension FunctionDeclSyntax {
    var hasImplicitReturn: Bool {
        guard let body else {
            return false
        }

        return body.statements.count == 1 &&
            signature.output != nil &&
            signature.output?.isReturningVoid == false
    }
}

extension ReturnClauseSyntax {
    var isReturningVoid: Bool {
        ["Void", "()"].contains(returnType.withoutTrivia().description.trimmed)
    }
}

extension SwiftSyntax.Trivia {
    func containsLineComment(_ comment: String) -> Bool {
        contains { piece in
            if case let .lineComment(commentText) = piece {
                return commentText.contains(comment)
            } else {
                return false
            }
        }
    }
}

extension Trivia? {
    func containsLineComment(_ comment: String) -> Bool {
        map { $0.containsLineComment(comment) } ?? false
    }
}
