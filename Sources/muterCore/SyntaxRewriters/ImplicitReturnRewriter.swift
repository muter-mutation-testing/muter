import SwiftSyntax

extension CodeBlockItemListSyntax {
    func withReturnStatementIfNeeded() -> CodeBlockItemListSyntax {
        guard count == 1,
              let codeBlockItem = first,
              !codeBlockItem.item.is(ReturnStmtSyntax.self),
              !codeBlockItem.item.is(SwitchStmtSyntax.self)  else {
            return self
        }
        
        let item = codeBlockItem.item.withoutTrivia()
        
        return SyntaxFactory.makeCodeBlockItemList([
            codeBlockItem.withItem(
                Syntax(
                    SyntaxFactory.makeReturnStmt(
                        returnKeyword: SyntaxFactory.makeReturnKeyword()
                            .appendingLeadingTrivia(.newlines(1))
                            .appendingTrailingTrivia(.spaces(1)),
                        expression: ExprSyntax(
                            item
                        )
                    )
                )
            )
        ])
    }
}

extension ClosureExprSyntax {
    var needsImplicitReturn: Bool {
        return statements.count == 1
    }
}

extension FunctionDeclSyntax {
    var needsImplicitReturn: Bool {
        return body?.statements.count == 1
    }
}

extension CodeBlockSyntax {
    var needsImplicitReturn: Bool {
        return statements.count == 1
    }
}

extension AccessorBlockSyntax {
    var needsImplicitReturn: Bool {
        let getter = accessors.first { $0.description.contains("get") }
        return getter?.body?.needsImplicitReturn == true
    }
}

extension PatternBindingSyntax {
    var needsImplicitReturn: Bool {
        return accessor?.as(CodeBlockSyntax.self)?.needsImplicitReturn == true
    }
}
