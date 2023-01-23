import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import SwiftSyntaxBuilder

typealias SchemataMutation = (
    id: String,
    syntaxMutation: CodeBlockItemListSyntax
)

struct MutationMapping {
    let schematas: [CodeBlockItemListSyntax: [Schemata]]
}

struct Schemata: Equatable {
    let id: String
    let syntaxMutation: CodeBlockItemListSyntax
    let positionInSourceCode: MutationPosition
    let snapshot: MutationOperatorSnapshot
}

func transform(
    node: SyntaxProtocol,
    mutatedSyntax: SyntaxProtocol
) -> CodeBlockItemListSyntax {
    let codeBlockItemListSyntax = node.codeBlockItemListSyntax
    let codeBlockDescription = codeBlockItemListSyntax.description
    let mutationDescription = mutatedSyntax.description
    guard let codeBlockTree = try? SyntaxParser.parse(source: codeBlockDescription),
          let mutationRangeInCodeBlock = codeBlockDescription.range(of: node.description) else {
        return codeBlockItemListSyntax
    }

    let mutationPositionInCodeBlock = codeBlockDescription.distance(to: mutationRangeInCodeBlock.lowerBound)
    let edit = SourceEdit(
        offset: mutationPositionInCodeBlock,
        length: mutatedSyntax.description.utf8.count,
        replacementLength: mutatedSyntax.description.utf8.count
    )

    let codeBlockWithMutation = codeBlockDescription.replacingCharacters(
        in: mutationRangeInCodeBlock,
        with: mutationDescription
    )

    let parseTransition = IncrementalParseTransition(
        previousTree: codeBlockTree,
        edits: ConcurrentEdits(edit)
    )

    guard let mutationParsed = try? SyntaxParser.parse(
        source: codeBlockWithMutation,
        parseTransition: parseTransition
    ) else {
        return codeBlockItemListSyntax
    }

    return mutationParsed.statements
}

func applyMutationSwitch(
    withOriginalSyntax originalSyntax: CodeBlockItemListSyntax,
    and mutations: [SchemataMutation]
) -> CodeBlockItemListSyntax {
    guard !mutations.isEmpty else {
        return originalSyntax
    }

    var mutationsToBeApplied = mutations
    let firstMutation = mutationsToBeApplied.removeFirst()
    var outterIfStatement = SyntaxFactory.makeIfStmt(
        labelName: nil,
        labelColon: nil,
        ifKeyword: .ifKeyword,
        conditions: buildSchemataCondition(
            withId: firstMutation.id
        ).buildConditionElementList(format: .init(indentWidth: 2)),
        body: SyntaxFactory.makeCodeBlock(
            leftBrace: .leftBraceSyntax,
            statements: firstMutation.syntaxMutation,
            rightBrace: .rightBraceSyntax
        ),
        elseKeyword: .elseKeyword,
        elseBody: Syntax(
            SyntaxFactory.makeCodeBlock(
                leftBrace: .leftBraceSyntax,
                statements: originalSyntax,
                rightBrace: .rightBraceSyntax
            )
        )
    )

    for mutation in mutationsToBeApplied {
        outterIfStatement = outterIfStatement.withElseBody(
            Syntax(
                SyntaxFactory.makeIfStmt(
                    labelName: nil,
                    labelColon: nil,
                    ifKeyword: .ifKeyword,
                    conditions: buildSchemataCondition(
                        withId: mutation.id
                    ).buildConditionElementList(format: .init(indentWidth: 2)),
                    body: SyntaxFactory.makeCodeBlock(
                        leftBrace: .leftBraceSyntax,
                        statements: mutation.syntaxMutation,
                        rightBrace: .rightBraceSyntax
                    ),
                    elseKeyword: .elseKeyword,
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

extension TokenSyntax {
    static var ifKeyword: TokenSyntax {
        SyntaxFactory
            .makeIfKeyword()
            .withTrailingTrivia(.spaces(1))
    }
    
    static var elseKeyword: TokenSyntax {
        SyntaxFactory.makeElseKeyword()
            .withTrailingTrivia(.spaces(1))
            .withLeadingTrivia(.spaces(1))
    }
    
    static var leftBraceSyntax: TokenSyntax {
        SyntaxFactory.makeLeftBraceToken()
    }
    
    static var rightBraceSyntax: TokenSyntax {
        SyntaxFactory.makeRightBraceToken()
    }
}

func buildSchemataCondition(withId id: String) -> ConditionElementList {
    ConditionElementList(
        arrayLiteral: ConditionElement(
            condition: SequenceExpr(
                elements: ExprList(
                    arrayLiteral: SubscriptExpr(
                        calledExpression:
                            MemberAccessExpr(
                                base: MemberAccessExpr(
                                    base: IdentifierExpr("ProcessInfo"),
                                    dot: TokenSyntax.period,
                                    name: TokenSyntax.identifier("processInfo")
                                ),
                                dot: TokenSyntax.period,
                                name: TokenSyntax.identifier("environment")
                            ),
                        leftBracket: TokenSyntax.leftSquareBracket,
                        rightBracket: TokenSyntax.rightSquareBracket,
                        argumentListBuilder: {
                            TupleExprElement(expression: StringLiteralExpr(id))
                        }
                    ),
                    BinaryOperatorExpr("!="),
                    NilLiteralExpr()
                )
            )
        )
    )
}

 func build() -> ConditionElementListSyntax {
     SyntaxFactory.makeConditionElementList([
         SyntaxFactory.makeConditionElement(
             condition: Syntax(
                 SyntaxFactory.makeSequenceExpr(
                     elements: SyntaxFactory.makeExprList([
                        ExprSyntax(
                            SyntaxFactory.makeSubscriptExpr(
                                calledExpression: SyntaxFactory.makeMemberAccessExpr(
                                    base:
                                        ExprSyntax(
                                            SyntaxFactory.makeMemberAccessExpr(
                                                base: ExprSyntax(SyntaxFactory.makeIdentifier("ProcessInfo"))!,//,
                                            dot: TokenSyntax.period,
                                            name: TokenSyntax.identifier("processInfo"),
                                            declNameArguments: nil),
                                        dot: TokenSyntax.period,
                                        name: TokenSyntax.identifier("environment"),
                                        declNameArguments: nil
                                        )
                                    )!
                                ),
                                leftBracket: TokenSyntax.leftSquareBracket,
                                argumentList: SyntaxFactory.makeTupleExprElementList([
                                    SyntaxFactory.makeTupleExprElement(
                                        label: nil,
                                        colon: nil,
                                        expression: ExprSyntax(SyntaxFactory.makeStringLiteral("id")),
                                        trailingComma: nil
                                    )
                                ]),
                                rightBracket: TokenSyntax.rightSquareBracket,
                                trailingClosure: nil,
                                additionalTrailingClosures: nil
                            )
                        )!
                     ])
                 )
             ),
             trailingComma: nil
         )
     ])
 }



func makeSchemataId(
    _ sourceFileInfo: SourceFileInfo,
    _ node: SyntaxProtocol
) -> String {
    let sourceLocation = node.endLocation(
        converter: SourceLocationConverter(
            file: sourceFileInfo.path,
            source: sourceFileInfo.source
        ),
        afterTrailingTrivia: true
    )

    return UUID().uuidString
}

extension SyntaxProtocol {
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
}
