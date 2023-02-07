import SwiftSyntax

final class Rewriter: SyntaxRewriter {
    private let schemataMappings: SchemataMutationMapping

    required init(_ schemataMappings: SchemataMutationMapping) {
        self.schemataMappings = schemataMappings
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> Syntax {
        guard let mutationsInNode = schemataMappings.schematas(node) else {
            return super.visit(node)
        }

        let newNode = applyMutationSwitch(
            withOriginalSyntax: node,
            and: mutationsInNode
        ).withLeadingTrivia(.spaces(1))

        return super.visit(newNode)
    }
}

class AddImportRewritter: SyntaxRewriter {
    override func visit(_ node: SourceFileSyntax) -> Syntax {
        return super.visit(
            SyntaxFactory.makeSourceFile(
                statements: insertImportFoundation(in: node.statements),
                eofToken: node.eofToken
            )
        )
    }
    
    private func insertImportFoundation(
        in node: CodeBlockItemListSyntax
    ) -> CodeBlockItemListSyntax {
        node.prepending(
            SyntaxFactory.makeCodeBlockItem(
                item: Syntax(
                    SyntaxFactory.makeImportDecl(
                        attributes: nil,
                        modifiers: nil,
                        importTok: SyntaxFactory.makeImportKeyword(),
                        importKind: nil,
                        path: SyntaxFactory.makeAccessPath([
                            SyntaxFactory.makeAccessPathComponent(
                                name: SyntaxFactory.makeIdentifier("Foundation")
                                    .withLeadingTrivia(.spaces(1))
                                    .withTrailingTrivia(.newlines(1)),
                                trailingDot: nil
                            )
                        ])
                    )
                ),
                semicolon: nil,
                errorTokens: nil
            )
        )
    }
}

class ImplicitReturnRewriter: SyntaxRewriter {
    override func visit(_ node: PatternBindingSyntax) -> Syntax {
        if let codeBlockItem = node.accessor?.as(CodeBlockSyntax.self) {
            return super.visit(
                makeCodeBlock(node, codeBlockItem)
            )
        }
        
        if let accessorBlock = node.accessor?.as(AccessorBlockSyntax.self) {
            return super.visit(
                makeAccessorBlock(node, accessorBlock)
            )
        }

        return super.visit(node)
    }
    
    private func makeAccessorBlock(
        _ node: PatternBindingSyntax,
        _ accessorBlock: AccessorBlockSyntax
    ) -> PatternBindingSyntax {
        guard let getter = accessorBlock.accessors.first(where: { $0.description.contains("get") }),
              let body = getter.body,
              body.statements.count == 1 else {
            return node
        }

        var accessors = accessorBlock.accessors.exclude { $0 == getter }
        
        accessors.append(
            SyntaxFactory.makeAccessorDecl(
                attributes: getter.attributes,
                modifier: getter.modifier,
                accessorKind: getter.accessorKind,
                parameter: getter.parameter,
                asyncKeyword: getter.asyncKeyword,
                throwsKeyword: getter.throwsKeyword,
                body:
                    SyntaxFactory.makeCodeBlock(
                        leftBrace: body.leftBrace,
                        statements: addReturnStatement(body.statements),
                        rightBrace: body.rightBrace
                    )
            )
        )
        
        return node.withAccessor(
            Syntax(
                SyntaxFactory.makeAccessorBlock(
                    leftBrace: accessorBlock.leftBrace,
                    accessors: SyntaxFactory.makeAccessorList(accessors),
                    rightBrace: accessorBlock.rightBrace
                )
            )
        )
    }
    
    private func makeCodeBlock(
        _ node: PatternBindingSyntax,
        _ codeBlockItem: CodeBlockSyntax
    ) -> PatternBindingSyntax {
        guard codeBlockItem.statements.count == 1 else {
            return node
        }
        
        return node.withAccessor(
            Syntax(
                SyntaxFactory.makeCodeBlock(
                    leftBrace: codeBlockItem.leftBrace,
                    statements: addReturnStatement(codeBlockItem.statements),
                    rightBrace: codeBlockItem.rightBrace
                )
            )
        )
    }
    
    // Check if we want to add implict return on functinos
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        if let body = node.body,
           body.statements.count == 1 {
            let newNode = node.withBody(
                SyntaxFactory.makeCodeBlock(
                    leftBrace: body.leftBrace,
                    statements: addReturnStatement(body.statements),
                    rightBrace: body.rightBrace
                )
            )
            
            return super.visit(newNode)
        }

        return super.visit(node)
    }
    
    // Check if we want to add implict return on closures
    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        if node.statements.count == 1 {
            let newNode = SyntaxFactory.makeClosureExpr(
                leftBrace: node.leftBrace,
                signature: node.signature,
                statements: addReturnStatement(node.statements),
                rightBrace: node.rightBrace
            )
            
            return super.visit(newNode)
        }

        return super.visit(node)
    }
    
    private func addReturnStatement(
        _ node: CodeBlockItemListSyntax
    ) -> CodeBlockItemListSyntax {
        guard let codeBlockItem = node.first,
              !codeBlockItem.item.is(ReturnStmtSyntax.self) else {
            return node
        }

        return SyntaxFactory.makeCodeBlockItemList([
            codeBlockItem.withItem(
                Syntax(
                    SyntaxFactory.makeReturnStmt(
                        returnKeyword: SyntaxFactory.makeReturnKeyword()
                            .withLeadingTrivia(.newlines(1))
                            .withTrailingTrivia(.spaces(1)),
                        expression: ExprSyntax(
                            codeBlockItem.item.withoutLeadingTrivia()
                        )
                    )
                )
            )
        ])
    }
}
