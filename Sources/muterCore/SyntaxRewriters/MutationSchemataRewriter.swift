import SwiftSyntax

final class MutationSchemataRewriter: SyntaxRewriter {
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

func applyMutationSwitch(
    withOriginalSyntax originalSyntax: CodeBlockItemListSyntax,
    and mutationsToBeApplied: [Schemata]
) -> CodeBlockItemListSyntax {
    guard !mutationsToBeApplied.isEmpty else {
        return originalSyntax
    }
    
    let shouldAddReturnStatement =
    originalSyntax.functionDeclarationSyntax?.body?.statements.count == 1 ||
    originalSyntax.accessorDeclGetSyntax?.body?.statements.count == 1 ||
    originalSyntax.patternBindingSyntax?.accessor?.as(CodeBlockSyntax.self)?.needsImplicitReturn == true ||
    originalSyntax.closureExprSyntax?.needsImplicitReturn == true

    var mutations = mutationsToBeApplied
    let firstMutation = mutations.removeFirst()
    var outterIfStatement = SyntaxFactory.makeIfStmt(
        labelName: nil,
        labelColon: nil,
        ifKeyword: SyntaxFactory
            .makeIfKeyword()
            .withTrailingTrivia(.spaces(1)),
        conditions: buildSchemataCondition(
            withId: firstMutation.id
        ),
        body: SyntaxFactory.makeCodeBlock(
            leftBrace: SyntaxFactory.makeLeftBraceToken()
                .withTrailingTrivia(
                    firstMutation.syntaxMutation.trailingTrivia ?? .spaces(0)
                ),
            statements: shouldAddReturnStatement ? firstMutation.syntaxMutation.withReturnStatementIfNeeded() : firstMutation.syntaxMutation,
            rightBrace: SyntaxFactory.makeRightBraceToken()
                .withLeadingTrivia(.newlines(1))
        ),
        elseKeyword: SyntaxFactory.makeElseKeyword()
            .withTrailingTrivia(.spaces(1))
            .withLeadingTrivia(.spaces(1)),
        elseBody: Syntax(
            SyntaxFactory.makeCodeBlock(
                leftBrace: SyntaxFactory.makeLeftBraceToken()
                    .withTrailingTrivia(
                        originalSyntax.trailingTrivia ?? .spaces(0)
                    ),
                statements: shouldAddReturnStatement ? originalSyntax.withReturnStatementIfNeeded() : originalSyntax,
                rightBrace: SyntaxFactory.makeRightBraceToken()
                    .withLeadingTrivia(.newlines(1))
            )
        )
    )

    for mutation in mutations {
        outterIfStatement = outterIfStatement.withElseBody(
            Syntax(
                SyntaxFactory.makeIfStmt(
                    labelName: nil,
                    labelColon: nil,
                    ifKeyword: SyntaxFactory
                        .makeIfKeyword()
                        .withTrailingTrivia(.spaces(1)),
                    conditions: buildSchemataCondition(
                        withId: mutation.id
                    ),
                    body: SyntaxFactory.makeCodeBlock(
                        leftBrace: SyntaxFactory.makeLeftBraceToken()
                            .withTrailingTrivia(
                                mutation.syntaxMutation.trailingTrivia ?? .spaces(0)
                            ),
                        statements: shouldAddReturnStatement ? mutation.syntaxMutation.withReturnStatementIfNeeded() : mutation.syntaxMutation,
                        rightBrace: SyntaxFactory.makeRightBraceToken()
                            .withLeadingTrivia(.newlines(1))
                    ),
                    elseKeyword: SyntaxFactory.makeElseKeyword()
                        .withTrailingTrivia(.spaces(1))
                        .withLeadingTrivia(.spaces(1)),
                    elseBody: outterIfStatement.elseBody.map(Syntax.init)
                )
            )
        )
    }

    return SyntaxFactory.makeCodeBlockItemList([
        SyntaxFactory.makeCodeBlockItem(
            item: Syntax(outterIfStatement),
            semicolon: nil,
            errorTokens: nil
        )
    ])
}
