import Foundation
import SwiftSyntax

struct MutationSwitch {
    static func apply(
        mutationSchemata: MutationSchemata,
        with originalSyntax: CodeBlockItemListSyntax
    ) -> CodeBlockItemListSyntax {
        guard !mutationSchemata.isEmpty else {
            return originalSyntax
        }
        
        let needsImplicitReturn = originalSyntax.needsImplicitReturn

        var schemata = mutationSchemata
        let firstSchema = schemata.removeFirst()
        var outterIfStatement = SyntaxFactory.makeIfStmt(
            labelName: nil,
            labelColon: nil,
            ifKeyword: SyntaxFactory
                .makeIfKeyword()
                .withTrailingTrivia(.spaces(1)),
            conditions: buildSchemataCondition(
                withId: firstSchema.id
            ),
            body: SyntaxFactory.makeCodeBlock(
                leftBrace: SyntaxFactory.makeLeftBraceToken()
                    .withTrailingTrivia(
                        firstSchema.syntaxMutation.trailingTrivia ?? .spaces(0)
                    ),
                statements: needsImplicitReturn
                    ? firstSchema.syntaxMutation.withReturnStatement()
                    : firstSchema.syntaxMutation,
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
                    statements: needsImplicitReturn
                        ? originalSyntax.withReturnStatement()
                        : originalSyntax,
                    rightBrace: SyntaxFactory.makeRightBraceToken()
                        .withLeadingTrivia(.newlines(1))
                )
            )
        )

        for schema in schemata {
            outterIfStatement = outterIfStatement.withElseBody(
                Syntax(
                    SyntaxFactory.makeIfStmt(
                        labelName: nil,
                        labelColon: nil,
                        ifKeyword: SyntaxFactory
                            .makeIfKeyword()
                            .withTrailingTrivia(.spaces(1)),
                        conditions: buildSchemataCondition(
                            withId: schema.id
                        ),
                        body: SyntaxFactory.makeCodeBlock(
                            leftBrace: SyntaxFactory.makeLeftBraceToken()
                                .withTrailingTrivia(
                                    schema.syntaxMutation.trailingTrivia ?? .spaces(0)
                                ),
                            statements: needsImplicitReturn
                                ? schema.syntaxMutation.withReturnStatement()
                                : schema.syntaxMutation,
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
    
    private static func buildSchemataCondition(
        withId id: String
    ) -> ConditionElementListSyntax {
        return SyntaxFactory.makeConditionElementList([
            SyntaxFactory.makeConditionElement(
                condition: Syntax(
                    SyntaxFactory.makeSequenceExpr(
                        elements: SyntaxFactory.makeExprList([
                            ExprSyntax(
                                SyntaxFactory.makeSubscriptExpr(
                                    calledExpression:
                                        ExprSyntax(
                                            SyntaxFactory.makeMemberAccessExpr(
                                                base:
                                                    ExprSyntax(
                                                        SyntaxFactory.makeMemberAccessExpr(
                                                            base: ExprSyntax(
                                                                SyntaxFactory.makeIdentifierExpr(
                                                                    identifier:
                                                                        SyntaxFactory.makeIdentifier("ProcessInfo"),
                                                                    declNameArguments: nil
                                                                )
                                                            ),
                                                            dot: SyntaxFactory.makePeriodToken(),
                                                            name: SyntaxFactory.makeIdentifier("processInfo"),
                                                            declNameArguments: nil
                                                        )),
                                                dot: SyntaxFactory.makePeriodToken(),
                                                name: SyntaxFactory.makeIdentifier("environment"),
                                                declNameArguments: nil
                                            )
                                        ),
                                    leftBracket: SyntaxFactory.makeLeftSquareBracketToken(),
                                    argumentList:
                                        SyntaxFactory.makeTupleExprElementList([
                                            SyntaxFactory.makeTupleExprElement(
                                                label: nil,
                                                colon: nil,
                                                expression: ExprSyntax(
                                                    SyntaxFactory.makeStringLiteralExpr(id)
                                                ),
                                                trailingComma: nil
                                            )
                                        ]),
                                    rightBracket: SyntaxFactory.makeRightSquareBracketToken(),
                                    trailingClosure: nil,
                                    additionalTrailingClosures: nil
                                )
                            ),
                            ExprSyntax(
                                SyntaxFactory.makeBinaryOperatorExpr(
                                    operatorToken: SyntaxFactory.makeSpacedBinaryOperator("!=")
                                        .withLeadingTrivia(.spaces(1))
                                        .withTrailingTrivia(.spaces(1))
                                )
                            ),
                            ExprSyntax(
                                SyntaxFactory.makeNilLiteralExpr(
                                    nilKeyword: SyntaxFactory
                                        .makeNilKeyword()
                                        .withTrailingTrivia(.spaces(1))
                                )
                            )
                        ])
                    )
                ),
                trailingComma: nil
            )
        ])
    }
}

private extension CodeBlockItemListSyntax {
    func withReturnStatement() -> CodeBlockItemListSyntax {
        guard let codeBlockItem = first,
              !codeBlockItem.item.is(ReturnStmtSyntax.self),
              !codeBlockItem.item.is(SwitchStmtSyntax.self) else {
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
    
    var needsImplicitReturn: Bool {
        return count == 1 &&
        functionDeclarationSyntax?.needsImplicitReturn == true ||
        accessorDeclGetSyntax?.needsImplicitReturn == true ||
        patternBindingSyntax?.needsImplicitReturn == true ||
        closureExprSyntax?.needsImplicitReturn == true
    }
}

private extension CodeBlockItemListSyntax {
    var functionDeclarationSyntax: FunctionDeclSyntax? {
        return findInParent(FunctionDeclSyntax.self)
    }
    
    var accessorDeclGetSyntax: AccessorDeclSyntax? {
        if let accessor = findInParent(AccessorDeclSyntax.self),
           accessor.accessorKind.tokenKind == .contextualKeyword("get") {
            return accessor
        }
        
        return nil
    }
    
    var patternBindingSyntax: PatternBindingSyntax? {
        return findInParent(PatternBindingSyntax.self)
    }
    
    var closureExprSyntax: ClosureExprSyntax? {
        return findInParent(ClosureExprSyntax.self)
    }
    
    private func findInParent<T: SyntaxProtocol>(
        _ syntaxNodeType: T.Type
    ) -> T? {
        let syntax = Syntax(self)
        if let found = syntax.as(T.self) {
            return found
        }
        
        var parent = parent
        
        while parent?.is(T.self) == false {
            parent = parent?.parent
        }
        
        return parent?.as(T.self)
    }
}

extension ClosureExprSyntax {
    var needsImplicitReturn: Bool {
        return statements.count == 1
    }
}

private extension FunctionDeclSyntax {
    var needsImplicitReturn: Bool {
        return body?.statements.count == 1
    }
}

private extension CodeBlockSyntax {
    var needsImplicitReturn: Bool {
        return statements.count == 1
    }
}

private extension AccessorDeclSyntax {
    var needsImplicitReturn: Bool {
        return body?.needsImplicitReturn == true
    }
}

private extension PatternBindingSyntax {
    var needsImplicitReturn: Bool {
        return accessor?.as(CodeBlockSyntax.self)?.needsImplicitReturn == true
    }
}
