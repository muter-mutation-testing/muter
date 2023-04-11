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

class MuterVisitor: SyntaxAnyVisitor {
    let configuration: MuterConfiguration?
    let sourceFileInfo: SourceFileInfo
    let mutationOperatorId: MutationOperator.Id

    var sourceCodePreparationChange: MutationSourceCodePreparationChange = .null

    private(set) var schemataMappings: SchemataMutationMapping

    required init(
        configuration: MuterConfiguration? = nil,
        sourceFileInfo: SourceFileInfo,
        mutationOperatorId: MutationOperator.Id
    ) {
        self.configuration = configuration
        self.sourceFileInfo = sourceFileInfo
        self.mutationOperatorId = mutationOperatorId
        self.schemataMappings = SchemataMutationMapping(
            filePath: sourceFileInfo.path
        )
        super.init(viewMode: .all)
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

        return mutationPosition(
            for: sourceLocation
        )
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

        return mutationPosition(
            for: sourceLocation
        )
    }
    
    private func mutationPosition(
        for sourceLocation: SourceLocation
    ) -> MutationPosition {
        return MutationPosition(
            utf8Offset: sourceLocation.offset,
            line: (sourceLocation.line ?? 0) - sourceCodePreparationChange.newLines,
            column: sourceLocation.column ?? 0
        )
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

        let mutationPositionInCodeBlock = codeBlockDescription.distance(
            to: mutationRangeInCodeBlock.lowerBound
        )

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
        snapshot: MutationOperator.Snapshot
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
        for snapshot: MutationOperator.Snapshot
    ) -> MutationSchema {
        MutationSchema(
            filePath: sourceFileInfo.path,
            mutationOperatorId: mutationOperatorId,
            syntaxMutation: transform(
                node: syntax,
                mutatedSyntax: mutation
            ),
            position: position,
            snapshot: snapshot
        )
    }
}
