import Foundation
import SwiftSyntax
import SwiftSyntaxParser

func buildSchemataCondition(
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

func makeSchemataId(
    _ sourceFileInfo: SourceFileInfo,
    _ position: MutationPosition
) -> String {
    let fileName = URL(fileURLWithPath: sourceFileInfo.path)
        .deletingPathExtension()
        .lastPathComponent
    
    let line = position.line
    let column = position.column
    let offset = position.utf8Offset
    
    return "\(fileName)_\(line)_\(column)_\(offset)"
}

extension CodeBlockItemListSyntax {
    var functionDeclarationSyntax: FunctionDeclSyntax? {
        let syntax = Syntax(self)
        if syntax.is(FunctionDeclSyntax.self) {
            return syntax.as(FunctionDeclSyntax.self)!
        }
        
        var parent = parent
        
        while parent?.is(FunctionDeclSyntax.self) == false {
            parent = parent?.parent
        }
        
        return parent?.as(FunctionDeclSyntax.self)
    }
    
    var accessorDeclGetSyntax: AccessorDeclSyntax? {
        let syntax = Syntax(self)
        if syntax.is(AccessorDeclSyntax.self) {
            return syntax.as(AccessorDeclSyntax.self)!
        }
        
        var parent = parent
        
        while parent?.is(AccessorDeclSyntax.self) == false {
            parent = parent?.parent
        }
        
        if let accessor = parent?.as(AccessorDeclSyntax.self),
           accessor.accessorKind.tokenKind == .contextualKeyword("get") {
            return accessor
        }
        
        return nil
    }
    
    var patternBindingSyntax: PatternBindingSyntax? {
        let syntax = Syntax(self)
        if syntax.is(PatternBindingSyntax.self) {
            return syntax.as(PatternBindingSyntax.self)!
        }
        
        var parent = parent
        
        while parent?.is(PatternBindingSyntax.self) == false {
            parent = parent?.parent
        }
        
        return parent?.as(PatternBindingSyntax.self)
    }
    
    var closureExprSyntax: ClosureExprSyntax? {
        let syntax = Syntax(self)
        if syntax.is(ClosureExprSyntax.self) {
            return syntax.as(ClosureExprSyntax.self)!
        }
        
        var parent = parent
        
        while parent?.is(ClosureExprSyntax.self) == false {
            parent = parent?.parent
        }
        
        return parent?.as(ClosureExprSyntax.self)
    }
}
