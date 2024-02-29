import Foundation
import SwiftSyntax

enum MutationSwitch {
    static func apply(
        mutationSchemata: MutationSchemata,
        with originalSyntax: CodeBlockItemListSyntax
    ) -> CodeBlockItemListSyntax {
        guard !mutationSchemata.isEmpty else {
            return originalSyntax
        }

        var schemata = mutationSchemata
        let firstSchema = schemata.removeFirst()

        var previousElseBody = IfExprSyntax.ElseBody(
            CodeBlockSyntax(
                statements: originalSyntax,
                rightBrace: .rightBraceToken()
                    .withLeadingTrivia(originalSyntax.leadingTrivia)
            )
        )

        for schema in schemata {
            let elseBody = IfExprSyntax.ElseBody(
                IfExprSyntax(
                    ifKeyword: .keyword(.if)
                        .withTrailingTrivia(.spaces(1))
                        .withLeadingTrivia(previousElseBody.leadingTrivia),
                    conditions: buildSchemataCondition(
                        withId: schema.id
                    ),
                    body: CodeBlockSyntax(
                        statements: schema.syntaxMutation,
                        rightBrace: .rightBraceToken()
                            .withLeadingTrivia(schema.syntaxMutation.leadingTrivia)
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
                .withTrailingTrivia(.spaces(1))
                .withLeadingTrivia(originalSyntax.leadingTrivia),
            conditions: buildSchemataCondition(
                withId: firstSchema.id
            ),
            body: CodeBlockSyntax(
                statements: firstSchema.syntaxMutation,
                rightBrace: .rightBraceToken()
                    .withLeadingTrivia(originalSyntax.leadingTrivia)
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
                                    MemberAccessExprSyntax(
                                        base: MemberAccessExprSyntax(
                                            base: MemberAccessExprSyntax(
                                                period: .periodToken(presence: .missing),
                                                declName: DeclReferenceExprSyntax(
                                                    baseName: .identifier("ProcessInfo")
                                                )
                                            ),
                                            declName: DeclReferenceExprSyntax(
                                                baseName: .identifier("processInfo")
                                            )
                                        ),
                                        declName: DeclReferenceExprSyntax(
                                            baseName: .identifier("environment")
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
                                                        ),
                                                    ]
                                                ),
                                                closingQuote: .stringQuoteToken()
                                            )
                                        ),
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
                            ),
                        ])
                    )
                ),
                trailingComma: nil
            ),
        ])
    }
}
