import Foundation
import SwiftSyntax
import SwiftSyntaxParser

final class SchemataMutationMapping: Equatable {
    var count: Int {
        mappings.count
    }

    var isEmpty: Bool {
        mappings.isEmpty
    }
    
    var codeBlocks: [String] {
        mappings.keys.map(\.description).sorted()
    }
    
    var schematas: [Schemata] {
        Array(mappings.values).reduce([], +).sorted()
    }

    let filePath: String
    let mutationOperatorId: MutationOperator.Id
    
    fileprivate var mappings: [CodeBlockItemListSyntax: [Schemata]]

    convenience init(
        filePath: String = "",
        mutationOperatorId: MutationOperator.Id = .ror
    ) {
        self.init(
            filePath: filePath,
            mutationOperatorId: mutationOperatorId,
            mappings: [:]
        )
    }
    
    fileprivate init(
        filePath: String = "",
        mutationOperatorId: MutationOperator.Id = .ror,
        mappings: [CodeBlockItemListSyntax: [Schemata]]
    ) {
        self.filePath = filePath
        self.mutationOperatorId = mutationOperatorId
        self.mappings = mappings
    }

    func add(
        _ codeBlockSyntax: CodeBlockItemListSyntax,
        _ schemata: Schemata
    ) {
        mappings[codeBlockSyntax, default: []].append(schemata)
    }
    
    func add(
        _ codeBlockSyntax: CodeBlockItemListSyntax,
        _ schematas: [Schemata]
    ) {
        mappings[codeBlockSyntax, default: []].append(contentsOf: schematas)
    }

    func schematas(
        _ codeBlockSyntax: CodeBlockItemListSyntax
    ) -> [Schemata]? {
        mappings[codeBlockSyntax]
    }
    
    func excludePoints(_ mutationPoints: [MutationPosition]) {
        for (codeBlock, schematas) in mappings {
            mappings[codeBlock] = schematas.exclude {
                mutationPoints.contains($0.positionInSourceCode)
            }
        }
    }
    
    static func + (
        lhs: SchemataMutationMapping,
        rhs: SchemataMutationMapping
    ) -> SchemataMutationMapping {
        let result = SchemataMutationMapping(
            filePath: lhs.filePath,
            mutationOperatorId: lhs.mutationOperatorId
        )

        let mergedMappgins = lhs.mappings.merging(rhs.mappings) { $0 + $1 }

        mergedMappgins.forEach { (codeBlock, schematas) in
            result.add(codeBlock, schematas)
        }
        
        return result
    }
    
    static func == (
        lhs: SchemataMutationMapping,
        rhs: SchemataMutationMapping
    ) -> Bool {
        lhs.codeBlocks == rhs.codeBlocks &&
        lhs.schematas == rhs.schematas
    }
}

extension SchemataMutationMapping: CustomStringConvertible, CustomDebugStringConvertible {
    var debugDescription: String { description }
    
    var description: String {
        let description = mappings.reduce(into: "") { (accum, pair) in
            accum +=
            """
            source: "\(pair.key.scapedDescription)",
            schematas: \(pair.value)
            """
        }
        return """
        SchemataMutationMapping(
            \(description)
        )
        """
    }
}

struct Schemata {
    let id: String
    let syntaxMutation: CodeBlockItemListSyntax
    let positionInSourceCode: MutationPosition
    let snapshot: MutationOperatorSnapshot
}

extension Schemata: Equatable {
    static func == (lhs: Schemata, rhs: Schemata) -> Bool {
        lhs.id == rhs.id &&
        lhs.syntaxMutation.description == rhs.syntaxMutation.description &&
        lhs.positionInSourceCode == rhs.positionInSourceCode &&
        lhs.snapshot == rhs.snapshot
    }
}

extension Schemata: CustomStringConvertible, CustomDebugStringConvertible {
    var debugDescription: String { description }
    
    var description: String {
        """
        Schemata(
            id: "\(id)",
            syntaxMutation: "\(syntaxMutation.scapedDescription)",
            positionInSourceCode: \(positionInSourceCode),
            snapshot: \(snapshot)
        )
        """
    }
}

private extension SyntaxProtocol {
    var scapedDescription: String {
        description.replacingOccurrences(
            of: "\n",
            with: "\\n"
        )
        .replacingOccurrences(
            of: "\"",
            with: "\\\""
        )
    }
}

extension Schemata: Comparable {
    static func < (
        lhs: Schemata,
        rhs: Schemata
    ) -> Bool {
        lhs.id < rhs.id
    }
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
    and mutationsToBeApplied: [Schemata]
) -> CodeBlockItemListSyntax {
    guard !mutationsToBeApplied.isEmpty else {
        return originalSyntax
    }

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
            statements: firstMutation.syntaxMutation,
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
                statements: originalSyntax,
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
                        statements: mutation.syntaxMutation,
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

func buildSchemataCondition(withId id: String) -> ConditionElementListSyntax {
    SyntaxFactory.makeConditionElementList([
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
    let fileName = URL(
        string: sourceFileInfo.path)?
        .deletingLastPathComponent()
        .lastPathComponent ?? ""
    
    let line = position.line
    let column = position.column
    let offset = position.utf8Offset
    
    return "\(fileName)_@\(line)_\(offset)_\(column)"
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
