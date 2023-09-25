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

        var previousElseBody = IfExprSyntax.ElseBody(
            CodeBlockSyntax(
                leftBrace: .leftBraceToken()
                    .withTrailingTrivia(
                        originalSyntax.trailingTrivia
                    ),
                statements: needsImplicitReturn
                    ? originalSyntax.withReturnStatement()
                    : originalSyntax,
                rightBrace: .rightBraceToken()
                    .withLeadingTrivia(.newlines(1))
            )
        )

        for schema in schemata {
            let elseBody = IfExprSyntax.ElseBody(
                IfExprSyntax(
                    ifKeyword: .keyword(.if).withTrailingTrivia(.spaces(1)),
                    conditions: buildSchemataCondition(
                        withId: schema.id
                    ),
                    body: CodeBlockSyntax(
                        leftBrace: .leftBraceToken()
                            .withTrailingTrivia(
                                schema.syntaxMutation.trailingTrivia
                            ),
                        statements: needsImplicitReturn
                            ? schema.syntaxMutation.withReturnStatement()
                            : schema.syntaxMutation,
                        rightBrace: .rightBraceToken()
                            .withLeadingTrivia(.newlines(1))
                    ),
                    elseKeyword: .keyword(.else)
                        .withTrailingTrivia(.spaces(1))
                        .withLeadingTrivia(.spaces(1)),
                    elseBody: previousElseBody
                )
            )

            previousElseBody = elseBody
        }

        let outterIfStatement = IfExprSyntax(
            ifKeyword: .keyword(.if)
                .withTrailingTrivia(.spaces(1)),
            conditions: buildSchemataCondition(
                withId: firstSchema.id
            ),
            body: CodeBlockSyntax(
                leftBrace: .leftBraceToken()
                    .withTrailingTrivia(
                        firstSchema.syntaxMutation.trailingTrivia
                    ),
                statements: needsImplicitReturn
                    ? firstSchema.syntaxMutation.withReturnStatement()
                    : firstSchema.syntaxMutation,
                rightBrace: .rightBraceToken()
                    .withLeadingTrivia(.newlines(1))
            ),
            elseKeyword: .keyword(.else)
                .withTrailingTrivia(.spaces(1))
                .withLeadingTrivia(.spaces(1)),
            elseBody: previousElseBody
        )

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
                                SubscriptCallExprSyntax(
                                    calledExpression:
                                    ExprSyntax(
                                        MemberAccessExprSyntax(
                                            base:
                                            ExprSyntax(
                                                MemberAccessExprSyntax(
                                                    base: ExprSyntax(
                                                        DeclReferenceExprSyntax(
                                                            baseName: .identifier("ProcessInfo"),
                                                            argumentNames: nil
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
                                    leftSquare: .leftSquareToken(),
                                    arguments:
                                    LabeledExprListSyntax([
                                        LabeledExprSyntax(
                                            label: nil,
                                            colon: nil,
                                            expression: StringLiteralExprSyntax(
                                                openingQuote: .stringQuoteToken(),
                                                segments: StringLiteralSegmentListSyntax(
                                                    [
                                                        .stringSegment(
                                                            StringSegmentSyntax(
                                                                content:
                                                                .stringSegment(id)
                                                            )
                                                        )
                                                    ]
                                                ),
                                                closingQuote: .stringQuoteToken()
                                            )
                                        )
                                    ]),
                                    rightSquare: .rightSquareToken(),
                                    trailingClosure: nil,
                                    additionalTrailingClosures: []
                                )
                            ),
                            ExprSyntax(
                                BinaryOperatorExprSyntax(
                                    operator: .binaryOperator("!=")
                                        .withLeadingTrivia(.spaces(1))
                                        .withTrailingTrivia(.spaces(1))
                                )
                            ),
                            ExprSyntax(
                                NilLiteralExprSyntax(
                                    nilKeyword: .keyword(.nil)
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
              !codeBlockItem.item.is(SwitchExprSyntax.self)
        else {
            return self
        }

        let item = codeBlockItem.item.withoutTrivia()

        return CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                leadingTrivia: codeBlockItem.leadingTrivia,
                item: CodeBlockItemSyntax.Item(
                    ReturnStmtSyntax(
                        returnKeyword: .keyword(.return)
                            .appendingLeadingTrivia(.newlines(1))
                            .appendingTrailingTrivia(.spaces(1)),
                        expression: ExprSyntax(
                            item
                        )
                    )
                ),
                semicolon: codeBlockItem.semicolon,
                trailingTrivia: codeBlockItem.trailingTrivia
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
           accessor.accessorSpecifier.tokenKind == .keyword(.get) {
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
        accessorBlock?.as(CodeBlockSyntax.self)?.needsImplicitReturn == true
    }
}
