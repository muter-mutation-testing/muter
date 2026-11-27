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
            let syntaxMutation = schema.syntaxMutation
            let elseBody = IfExprSyntax.ElseBody(
                IfExprSyntax(
                    ifKeyword: .keyword(.if)
                        .withTrailingTrivia(.spaces(1))
                        .withLeadingTrivia(previousElseBody.leadingTrivia),
                    conditions: buildSchemataCondition(
                        withId: schema.id
                    ),
                    body: CodeBlockSyntax(
                        statements: syntaxMutation,
                        rightBrace: .rightBraceToken()
                            .withLeadingTrivia(syntaxMutation.leadingTrivia)
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

    /// `__SwiftMutator.activeMutant == <id>`. `activeMutant` is the number in `MUTER_ACTIVE_MUTANT`,
    /// read once for each file (see `MuterRewriter`), so each check is one integer compare.
    private static func buildSchemataCondition(
        withId id: Int
    ) -> ConditionElementListSyntax {
        ConditionElementListSyntax([
            ConditionElementSyntax(
                condition: ConditionElementSyntax.Condition(
                    SequenceExprSyntax(
                        elements: ExprListSyntax([
                            ExprSyntax(
                                MemberAccessExprSyntax(
                                    base: DeclReferenceExprSyntax(
                                        baseName: .identifier(MuterRewriter.environmentCacheName)
                                    ),
                                    declName: DeclReferenceExprSyntax(
                                        baseName: .identifier("activeMutant")
                                    )
                                )
                            ),
                            ExprSyntax(
                                BinaryOperatorExprSyntax(
                                    operator: .binaryOperator("==")
                                        .withLeadingTrivia(.spaces(1))
                                        .withTrailingTrivia(.spaces(1))
                                )
                            ),
                            ExprSyntax(
                                IntegerLiteralExprSyntax(
                                    literal: .integerLiteral(String(id))
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
