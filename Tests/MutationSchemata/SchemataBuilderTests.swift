import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import TestingExtensions

@testable import muterCore

final class SchemataBuilderTests: XCTestCase {
    func test_syntaxTransformShouldChangeCodeBlockSyntax() throws {
        let source = try SyntaxParser.parse(source: "a != b")
        
        let visitor = Visitor()
        visitor.walk(source)
        
        let actual = transform(
            node: visitor.targetToken,
            mutatedSyntax: visitor.mutatedToken
        )
        
        XCTAssertTrue(actual.syntaxNodeType == CodeBlockItemListSyntax.self)
        XCTAssertEqual(actual.description, "a == b")
    }
    
    func test__() throws {
        let originalSyntax = try SyntaxParser.parse(source: "a != b").statements
        let mutatedSyntax = try SyntaxParser.parse(source: "a == b").statements
        let schemataMutation: [SchemataMutation] = [(
            id: "switch-id",
            syntaxMutation: mutatedSyntax
        )]

        let actualMutationSwitch = applyMutationSwitch(
            withOriginalSyntax: originalSyntax,
            and: schemataMutation
        )
        
        XCTAssertEqual(
            actualMutationSwitch.description,
            "if ProcessInfo.processInfo.environment[\"switch-id\"] != nil {a == b} else {a != b}"
        )
    }
}

private class Visitor: SyntaxAnyVisitor {
    var targetToken: TokenSyntax!
    var mutatedToken: TokenSyntax!
    
    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        if let token = node.as(TokenSyntax.self),
           token.parent?.is(BinaryOperatorExprSyntax.self) == true {
            targetToken = token
            mutatedToken = SyntaxFactory.makeToken(
                .spacedBinaryOperator("=="),
                presence: .present,
                leadingTrivia: token.leadingTrivia,
                trailingTrivia: token.trailingTrivia
            )
        }

        return .visitChildren
    }
}
