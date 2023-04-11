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

        var outerIfStatement = IfStmtSyntax(
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
            outerIfStatement = outerIfStatement.withElseBody(
                IfStmtSyntax.ElseBody(
                    IfStmtSyntax(
                        ifKeyword: .ifKeyword()
                            .withTrailingTrivia(.spaces(1)),
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
                        elseBody: outerIfStatement.elseBody.flatMap(IfStmtSyntax.ElseBody.init)
                    )
                )
            )
        }

        return CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                item: CodeBlockItemSyntax.Item(outerIfStatement),
                semicolon: nil,
                errorTokens: nil
            )
        ])
    }
    
    private static func buildSchemataCondition(
        withId id: String
    ) -> ConditionElementListSyntax {
        return ConditionElementListSyntax([
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
                                                        )),
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
                                                    StringLiteralExprSyntax(content: id)
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

// Copied from https://github.com/apple/swift-syntax/blob/main/Sources/SwiftSyntaxBuilder/ConvenienceInitializers.swift#L267
private extension StringLiteralExprSyntax {
  private enum PoundState {
    case afterQuote, afterBackslash, none
  }

  private static func requiresEscaping(_ content: String) -> (Bool, poundCount: Int) {
    var countingPounds = false
    var consecutivePounds = 0
    var maxPounds = 0
    var requiresEscaping = false

    for c in content {
      switch (countingPounds, c) {
      // Normal mode: scanning for characters that can be followed by pounds.
      case (false, "\""), (false, "\\"):
        countingPounds = true
        requiresEscaping = true
      case (false, _):
        continue

      // Special mode: counting a sequence of pounds until we reach its end.
      case (true, "#"):
        consecutivePounds += 1
        maxPounds = max(maxPounds, consecutivePounds)
      case (true, _):
        countingPounds = false
        consecutivePounds = 0
      }
    }

    return (requiresEscaping, poundCount: maxPounds)
  }

  /// Creates a string literal, optionally specifying quotes and delimiters.
  /// If `openDelimiter` and `closeDelimiter` are `nil`, automatically determines
  /// the number of `#`s needed to express the string as-is without any escapes.
  init(
    openDelimiter: TokenSyntax? = nil,
    openQuote: TokenSyntax = .stringQuoteToken(),
    content: String,
    closeQuote: TokenSyntax = .stringQuoteToken(),
    closeDelimiter: TokenSyntax? = nil
  ) {
    var openDelimiter = openDelimiter
    var closeDelimiter = closeDelimiter
    if openDelimiter == nil, closeDelimiter == nil {
      // Match potential escapes in the string
      let (requiresEscaping, poundCount) = Self.requiresEscaping(content)
      if requiresEscaping {
        // Use a delimiter that is exactly one longer
        openDelimiter = TokenSyntax.rawStringDelimiter(String(repeating: "#", count: poundCount + 1))
        closeDelimiter = openDelimiter
      }
    }

    let escapedContent = content.escapingForStringLiteral(usingDelimiter: closeDelimiter?.text ?? "", isMultiline: openQuote.rawTokenKind == .multilineStringQuote)
    let contentToken = TokenSyntax.stringSegment(escapedContent)
    let segment = StringSegmentSyntax(content: contentToken)
    let segments = StringLiteralSegmentsSyntax([.stringSegment(segment)])

    self.init(
      openDelimiter: openDelimiter,
      openQuote: openQuote,
      segments: segments,
      closeQuote: closeQuote,
      closeDelimiter: closeDelimiter
    )
  }
}

// Copied from https://github.com/apple/swift-syntax/blob/main/Sources/SwiftSyntaxBuilder/ConvenienceInitializers.swift#L180
extension String {
  /// Replace literal newlines with "\r", "\n", "\u{2028}", and ASCII control characters with "\0", "\u{7}"
  fileprivate func escapingForStringLiteral(usingDelimiter delimiter: String, isMultiline: Bool) -> String {
    // String literals cannot contain "unprintable" ASCII characters (control
    // characters, etc.) besides tab. As a matter of style, we also choose to
    // escape Unicode newlines like "\u{2028}" even though swiftc will allow
    // them in string literals.
    func needsEscaping(_ scalar: UnicodeScalar) -> Bool {
      if Character(scalar).isNewline {
        return true
      }

      if !scalar.isASCII || scalar.isPrintableASCII {
        return false
      }

      if scalar == "\t" {
        // Tabs need to be escaped in single-line string literals but not
        // multi-line string literals.
        return !isMultiline
      }
      return true
    }

    // Work at the Unicode scalar level so that "\r\n" isn't combined.
    var result = String.UnicodeScalarView()
    var input = self.unicodeScalars[...]
    while let firstNewline = input.firstIndex(where: needsEscaping(_:)) {
      result += input[..<firstNewline]

      result += "\\\(delimiter)".unicodeScalars
      switch input[firstNewline] {
      case "\r":
        result += "r".unicodeScalars
      case "\n":
        result += "n".unicodeScalars
      case "\t":
        result += "t".unicodeScalars
      case "\0":
        result += "0".unicodeScalars
      case let other:
        result += "u{\(String(other.value, radix: 16))}".unicodeScalars
      }
      input = input[input.index(after: firstNewline)...]
    }
    result += input

    return String(result)
  }
}

extension Unicode.Scalar {
    // Copied from https://github.com/apple/swift-syntax/blob/main/Sources/SwiftParser/Lexer/UnicodeScalarExtensions.swift#L148
    public var isPrintableASCII: Bool {
      // Exclude non-printables before the space character U+20, and anything
      // including and above the DEL character U+7F.
      return self.value >= 0x20 && self.value < 0x7F
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
