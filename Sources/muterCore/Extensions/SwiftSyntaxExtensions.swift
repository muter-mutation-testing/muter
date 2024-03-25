import SwiftSyntax

extension SyntaxProtocol {
    var escapedDescription: String {
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
        var trivia = leadingTrivia
        if !trivia.isEmpty {
            pieces.forEach { trivia = trivia.appending($0) }
            return withLeadingTrivia(trivia)
        } else {
            return withLeadingTrivia(Trivia(pieces: pieces))
        }
    }

    func appendingTrailingTrivia(
        _ pieces: TriviaPiece...
    ) -> Self {
        var trivia = trailingTrivia
        if !trivia.isEmpty {
            pieces.forEach { trivia = trivia.appending($0) }
            return withTrailingTrivia(trivia)
        } else {
            return withTrailingTrivia(Trivia(pieces: pieces))
        }
    }

    func withTrailingTrivia(
        _ trivia: Trivia?
    ) -> Self {
        var copy = self
        if let trivia {
            copy.trailingTrivia = trivia
        }

        return copy
    }

    func withLeadingTrivia(
        _ trivia: Trivia?
    ) -> Self {
        var copy = self
        if let trivia {
            copy.leadingTrivia = trivia
        }

        return copy
    }

    func withoutTrivia() -> Self {
        withLeadingTrivia([]).withTrailingTrivia([])
    }

    var allChildren: SyntaxChildren {
        children(viewMode: .all)
    }

    func containsLineComment(_ comment: String) -> Bool {
        leadingTrivia.containsLineComment(comment)
            || trailingTrivia.containsLineComment(comment)
    }
}

extension SyntaxChildren {
    var asArray: [Element] {
        var result: [Element] = []

        for el in self {
            result.append(el)
        }

        return result
    }

    func containsSyntaxKind(_ syntax: (some SyntaxProtocol).Type) -> Bool {
        asArray.containsSyntaxKind(syntax)
    }
}

extension [Syntax] {
    func containsSyntaxKind<A: SyntaxProtocol>(_ syntax: A.Type) -> Bool {
        contains { $0.is(A.self) }
    }
}

extension FunctionDeclSyntax {
    var hasImplicitReturn: Bool {
        guard let body else {
            return false
        }

        return body.statements.count == 1 &&
            signature.returnClause != nil &&
            signature.returnClause?.isReturningVoid == false
    }
}

extension ReturnClauseSyntax {
    var isReturningVoid: Bool {
        ["Void", "()"].contains(type.withoutTrivia().description.trimmed)
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
