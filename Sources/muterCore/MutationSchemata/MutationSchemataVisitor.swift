import SwiftSyntax
import SwiftSyntaxParser

final class MutationSourceCodePreparationChange: Equatable {
    static func == (
        lhs: MutationSourceCodePreparationChange,
        rhs: MutationSourceCodePreparationChange
    ) -> Bool {
        lhs.newLines == rhs.newLines
    }
    
    let newLines: Int
    
    init(
        newLines: Int
    ) {
        self.newLines = newLines
    }
}

extension MutationSourceCodePreparationChange: Nullable {
    static var null: MutationSourceCodePreparationChange {
        .init(
            newLines: 0
        )
    }
}

class MutationSchemataVisitor: SyntaxAnyVisitor {
    let configuration: MuterConfiguration?
    let sourceFileInfo: SourceFileInfo
    let mutationOperatorId: MutationOperator.Id

    var sourceCodePreparationChange: MutationSourceCodePreparationChange = .null

    private(set) var schemataMappings: SchemataMutationMapping

    required init(
        configuration: MuterConfiguration?,
        sourceFileInfo: SourceFileInfo,
        mutationOperatorId: MutationOperator.Id
    ) {
        self.configuration = configuration
        self.sourceFileInfo = sourceFileInfo
        self.mutationOperatorId = mutationOperatorId
        self.schemataMappings = SchemataMutationMapping(
            filePath: sourceFileInfo.path
        )
    }

    func location(
        for node: SyntaxProtocol
    ) -> MutationPosition {
        let converter = SourceLocationConverter(
            file: sourceFileInfo.path,
            source: sourceFileInfo.source
        )

        let sourceLocation = SourceLocation(
            offset: node.position.utf8Offset,
            converter: converter
        )

        let position = MutationPosition(
            sourceLocation: sourceLocation
        ).minusLine(sourceCodePreparationChange.newLines)

        return position
    }
    
    func endLocation(
        for node: SyntaxProtocol
    ) -> MutationPosition {
        let sourceLocation = node.endLocation(
            converter: SourceLocationConverter(
                file: sourceFileInfo.path,
                source: sourceFileInfo.source
            ),
            afterTrailingTrivia: true
        )

        let position = MutationPosition(
            sourceLocation: sourceLocation
        ).minusLine(sourceCodePreparationChange.newLines)

        return position
    }
    
    func transform(
        node: SyntaxProtocol,
        mutatedSyntax: SyntaxProtocol,
        at mutationRange: Range<String.Index>? = nil
    ) -> CodeBlockItemListSyntax {
        let codeBlockItemListSyntax = node.codeBlockItemListSyntax
        let codeBlockDescription = codeBlockItemListSyntax.description
        let mutationDescription = mutatedSyntax.description
        let range = mutationRange ?? codeBlockDescription.range(of: node.description)
        guard let codeBlockTree = try? SyntaxParser.parse(source: codeBlockDescription),
              let mutationRangeInCodeBlock = range else {
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
    
    func add(
        mutation: SyntaxProtocol,
        with syntax: SyntaxProtocol,
        at position: MutationPosition,
        snapshot: MutationOperatorSnapshot
    ) {
        let schemata = makeSchemata(
            with: syntax,
            mutation: mutation,
            at: position,
            for: snapshot
        )

        schemataMappings.add(
            syntax.codeBlockItemListSyntax,
            schemata
        )
    }
    
    func makeSchemata(
        with syntax: SyntaxProtocol,
        mutation: SyntaxProtocol,
        at position: MutationPosition,
        for snapshot: MutationOperatorSnapshot
    ) -> Schemata {
        Schemata(
            id: makeSchemataId(
                sourceFileInfo,
                position
            ),
            filePath: sourceFileInfo.path,
            mutationOperatorId: mutationOperatorId,
            syntaxMutation: transform(
                node: syntax,
                mutatedSyntax: mutation
            ),
            positionInSourceCode: position,
            snapshot: snapshot
        )
    }
}
//
//final class A: SyntaxRewriter {
//
//    override func visit(_ node: PatternBindingSyntax) -> Syntax {
//        if let codeBlockItem = node.accessor?.as(CodeBlockSyntax.self) {
//            return super.visit(
//                makeCodeBlock(node, codeBlockItem)
//            )
//        }
//        
//        if let accessorBlock = node.accessor?.as(AccessorBlockSyntax.self) {
//            return super.visit(
//                makeAccessorBlock(node, accessorBlock)
//            )
//        }
//
//        return super.visit(node)
//    }
//    
//    // Check if we want to add implict return on functinos
//    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
//        if let body = node.body,
//           node.needsImplicitReturn {
//            let newNode = node.withBody(
//                SyntaxFactory.makeCodeBlock(
//                    leftBrace: body.leftBrace,
//                    statements: addReturnStatement(body.statements),
//                    rightBrace: body.rightBrace
//                )
//            )
//            
//            return super.visit(newNode)
//        }
//
//        return super.visit(node)
//    }
//    
//    // Check if we want to add implict return on closures
//    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
//        if node.needsImplicitReturn {
//            let newNode = SyntaxFactory.makeClosureExpr(
//                leftBrace: node.leftBrace,
//                signature: node.signature,
//                statements: addReturnStatement(
//                    node.statements
//                ),
//                rightBrace: node.rightBrace
//            )
//            
//            return super.visit(newNode)
//        }
//
//        return super.visit(node)
//    }
//    
//    private func makeAccessorBlock(
//        _ node: PatternBindingSyntax,
//        _ accessorBlock: AccessorBlockSyntax
//    ) -> PatternBindingSyntax {
//        guard node.needsImplicitReturn else {
//            return node
//        }
//
//        let getter = accessorBlock.accessors.first { $0.description.contains("get") }!
//        
//        guard let body = getter.body else {
//            return node
//        }
//
//        var accessors = accessorBlock.accessors.exclude { $0 == getter }
//        
//        accessors.append(
//            SyntaxFactory.makeAccessorDecl(
//                attributes: getter.attributes,
//                modifier: getter.modifier,
//                accessorKind: getter.accessorKind,
//                parameter: getter.parameter,
//                asyncKeyword: getter.asyncKeyword,
//                throwsKeyword: getter.throwsKeyword,
//                body:
//                    SyntaxFactory.makeCodeBlock(
//                        leftBrace: body.leftBrace,
//                        statements: addReturnStatement(body.statements),
//                        rightBrace: body.rightBrace
//                    )
//            )
//        )
//        
//        return node.withAccessor(
//            Syntax(
//                SyntaxFactory.makeAccessorBlock(
//                    leftBrace: accessorBlock.leftBrace,
//                    accessors: SyntaxFactory.makeAccessorList(accessors),
//                    rightBrace: accessorBlock.rightBrace
//                )
//            )
//        )
//    }
//    
//    private func makeCodeBlock(
//        _ node: PatternBindingSyntax,
//        _ codeBlockItem: CodeBlockSyntax
//    ) -> PatternBindingSyntax {
//        guard codeBlockItem.needsImplicitReturn else {
//            return node
//        }
//        
//        return node.withAccessor(
//            Syntax(
//                SyntaxFactory.makeCodeBlock(
//                    leftBrace: codeBlockItem.leftBrace,
//                    statements: addReturnStatement(codeBlockItem.statements),
//                    rightBrace: codeBlockItem.rightBrace
//                )
//            )
//        )
//    }
//    
//    private func addReturnStatement(
//        _ node: CodeBlockItemListSyntax
//    ) -> CodeBlockItemListSyntax {
//        guard let codeBlockItem = node.first,
//              !codeBlockItem.item.is(ReturnStmtSyntax.self),
//              !codeBlockItem.item.is(SwitchStmtSyntax.self)  else {
//            return node
//        }
//
//        return SyntaxFactory.makeCodeBlockItemList([
//            codeBlockItem.withItem(
//                Syntax(
//                    SyntaxFactory.makeReturnStmt(
//                        returnKeyword: SyntaxFactory.makeReturnKeyword()
//                            .appendingLeadingTrivia(.newlines(1))
//                            .appendingTrailingTrivia(.spaces(1)),
//                        expression: ExprSyntax(
//                            codeBlockItem.item.withoutLeadingTrivia()
//                        )
//                    )
//                )
//            )
//        ])
//    }
//}
