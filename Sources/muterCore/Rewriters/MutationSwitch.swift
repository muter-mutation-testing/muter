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
        var outterIfStatement = IfStmtSyntax(
            ifKeyword: .ifKeyword()
                .withTrailingTrivia(.spaces(1)),
            conditions: buildSchemataCondition(
                withId: firstSchema.id
            ),
            body: CodeBlockSyntax(
                leftBrace: .leftBraceToken()
                    .withTrailingTrivia(
                        firstSchema.syntaxMutation.trailingTrivia ?? .spaces(0)
                    ),
                statements: needsImplicitReturn
                    ? firstSchema.syntaxMutation.withReturnStatement()
                    : firstSchema.syntaxMutation,
                rightBrace: .rightBraceToken()
                    .withLeadingTrivia(.newlines(1))
            ),
            elseKeyword: .elseKeyword()
                .withTrailingTrivia(.spaces(1))
                .withLeadingTrivia(.spaces(1)),
            elseBody: IfStmtSyntax.ElseBody(
                CodeBlockSyntax(
                    leftBrace: .leftBraceToken()
                        .withTrailingTrivia(
                            originalSyntax.trailingTrivia ?? .spaces(0)
                        ),
                    statements: needsImplicitReturn
                        ? originalSyntax.withReturnStatement()
                        : originalSyntax,
                    rightBrace: .rightBraceToken()
                        .withLeadingTrivia(.newlines(1))
                )
            )
        )

        for schema in schemata {
            outterIfStatement = outterIfStatement.withElseBody(
                IfStmtSyntax.ElseBody(
                    IfStmtSyntax(
                        ifKeyword: .ifKeyword().withTrailingTrivia(.spaces(1)),
                        conditions: buildSchemataCondition(
                            withId: schema.id
                        ),
                        body: CodeBlockSyntax(
                            leftBrace: .leftBraceToken()
                                .withTrailingTrivia(
                                    schema.syntaxMutation.trailingTrivia ?? .spaces(0)
                                ),
                            statements: needsImplicitReturn
                                ? schema.syntaxMutation.withReturnStatement()
                                : schema.syntaxMutation,
                            rightBrace: .rightBraceToken()
                                .withLeadingTrivia(.newlines(1))
                        ),
                        elseKeyword: .elseKeyword()
                            .withTrailingTrivia(.spaces(1))
                            .withLeadingTrivia(.spaces(1)),
                        elseBody: outterIfStatement.elseBody.flatMap(IfStmtSyntax.ElseBody.init)
                    )
                )
            )
        }

        return CodeBlockItemListSyntax([
            CodeBlockItemSyntax(item: .init(outterIfStatement))
        ])
    }

    private static func buildSchemataCondition(
        withId id: String
    ) -> ConditionElementListSyntax {
        ConditionElementListSyntax([
            ConditionElementSyntax(
                condition: ConditionElementSyntax.Condition(
                    SequenceExprSyntax(
                        elements: ExprListSyntax([
                            ExprSyntax(
                                SubscriptExprSyntax(
                                    calledExpression:
                                    ExprSyntax(
                                        MemberAccessExprSyntax(
                                            base:
                                            ExprSyntax(
                                                MemberAccessExprSyntax(
                                                    base: ExprSyntax(
                                                        IdentifierExprSyntax(
                                                            identifier: .identifier("ProcessInfo"),
                                                            declNameArguments: nil
                                                        )
                                                    ),
                                                    dot: .periodToken(),
                                                    name: .identifier("processInfo"),
                                                    declNameArguments: nil
                                                )
                                            ),
                                            dot: .periodToken(),
                                            name: .identifier("environment"),
                                            declNameArguments: nil
                                        )
                                    ),
                                    leftBracket: .leftSquareBracketToken(),
                                    argumentList:
                                    TupleExprElementListSyntax([
                                        TupleExprElementSyntax(
                                            label: nil,
                                            colon: nil,
                                            expression: ExprSyntax(
                                                StringLiteralExprSyntax(
                                                    openQuote: .stringQuoteToken(),
                                                    segments: StringLiteralSegmentsSyntax(
                                                        [.stringSegment(StringSegmentSyntax(
                                                            content: TokenSyntax
                                                                .stringSegment(id)
                                                        ))]
                                                    ),
                                                    closeQuote: .stringQuoteToken()
                                                )
                                            ),
                                            trailingComma: nil
                                        )
                                    ]),
                                    rightBracket: .rightSquareBracketToken(),
                                    trailingClosure: nil,
                                    additionalTrailingClosures: nil
                                )
                            ),
                            ExprSyntax(
                                BinaryOperatorExprSyntax(
                                    operatorToken: .spacedBinaryOperator("!=")
                                        .withLeadingTrivia(.spaces(1))
                                        .withTrailingTrivia(.spaces(1))
                                )
                            ),
                            ExprSyntax(
                                NilLiteralExprSyntax(
                                    nilKeyword: .nilKeyword()
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
              !codeBlockItem.item.is(SwitchStmtSyntax.self)
        else {
            return self
        }

        let item = codeBlockItem.item.withoutTrivia()

        return CodeBlockItemListSyntax([
            codeBlockItem.withItem(
                CodeBlockItemSyntax.Item(
                    ReturnStmtSyntax(
                        returnKeyword: .returnKeyword()
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
        count == 1 &&
            functionDeclarationSyntax?.needsImplicitReturn == true ||
            accessorDeclGetSyntax?.needsImplicitReturn == true ||
            patternBindingSyntax?.needsImplicitReturn == true ||
            closureExprSyntax?.needsImplicitReturn == true
    }
}

private extension CodeBlockItemListSyntax {
    var functionDeclarationSyntax: FunctionDeclSyntax? {
        findInParent(FunctionDeclSyntax.self)
    }

    var accessorDeclGetSyntax: AccessorDeclSyntax? {
        if let accessor = findInParent(AccessorDeclSyntax.self),
           accessor.accessorKind.tokenKind == .contextualKeyword("get") {
            return accessor
        }

        return nil
    }

    var patternBindingSyntax: PatternBindingSyntax? {
        findInParent(PatternBindingSyntax.self)
    }

    var closureExprSyntax: ClosureExprSyntax? {
        findInParent(ClosureExprSyntax.self)
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
        statements.count == 1
    }
}

private extension FunctionDeclSyntax {
    var needsImplicitReturn: Bool {
        body?.statements.count == 1
    }
}

private extension CodeBlockSyntax {
    var needsImplicitReturn: Bool {
        statements.count == 1
    }
}

private extension AccessorDeclSyntax {
    var needsImplicitReturn: Bool {
        body?.needsImplicitReturn == true
    }
}

private extension PatternBindingSyntax {
    var needsImplicitReturn: Bool {
        accessor?.as(CodeBlockSyntax.self)?.needsImplicitReturn == true
    }
}
