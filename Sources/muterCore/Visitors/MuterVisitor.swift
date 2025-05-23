import SwiftParser
import SwiftSyntax

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
    private let muterDisableTag = "muter:disable"
    private let muterEnabledTag = "muter:enable"
    private(set) var isDisabled = false

    let configuration: MuterConfiguration?
    let sourceCodeInfo: SourceCodeInfo
    let mutationOperatorId: MutationOperator.Id
    let regionsWithoutCoverage: [Region]

    var sourceCodePreparationChange: MutationSourceCodePreparationChange = .null

    private(set) var schemataMappings: SchemataMutationMapping

    required init(
        configuration: MuterConfiguration? = nil,
        sourceCodeInfo: SourceCodeInfo,
        mutationOperatorId: MutationOperator.Id,
        regionsWithoutCoverage: [Region]
    ) {
        self.configuration = configuration
        self.sourceCodeInfo = sourceCodeInfo
        self.mutationOperatorId = mutationOperatorId
        self.regionsWithoutCoverage = regionsWithoutCoverage

        schemataMappings = SchemataMutationMapping(
            filePath: sourceCodeInfo.path
        )

        super.init(viewMode: .sourceAccurate)
    }

    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        guard hasTestCoverage(node) else {
            return .skipChildren
        }

        checkNodeForDisableTag(node)

        return super.visitAny(node)
    }

    func checkNodeForDisableTag(_ node: SyntaxProtocol) {
        isDisabled = isDisabled
            && !node.containsLineComment(muterEnabledTag)
            || !isDisabled
            && node.containsLineComment(muterDisableTag)
    }

    private func hasTestCoverage(
        _ node: SyntaxProtocol
    ) -> Bool {
        guard !regionsWithoutCoverage.isEmpty else {
            return true
        }

        let nodeRegion = nodeRegion(node)

        return regionsWithoutCoverage.include { $0.contains(nodeRegion) }.isEmpty
    }

    private func nodeRegion(_ node: SyntaxProtocol) -> Region {
        let start = startLocation(for: node)
        let end = endLocation(for: node)

        return Region(
            lineStart: start.line,
            columnStart: start.column,
            lineEnd: end.line,
            columnEnd: end.column
        )
    }

    func startLocation(
        for node: SyntaxProtocol
    ) -> MutationPosition {
        let converter = SourceLocationConverter(
            fileName: sourceCodeInfo.path,
            tree: sourceCodeInfo.code
        )

        let sourceLocation = node.startLocation(
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
                fileName: sourceCodeInfo.path,
                tree: sourceCodeInfo.code
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
        MutationPosition(
            utf8Offset: sourceLocation.offset,
            line: sourceLocation.line - sourceCodePreparationChange.newLines,
            column: sourceLocation.column
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
        let codeBlockTree = Parser.parse(source: codeBlockDescription)
        guard let range
        else {
            return codeBlockItemListSyntax
        }

        let mutationPositionInCodeBlock = codeBlockDescription.distance(
            to: range.lowerBound
        )

        let edit = IncrementalEdit(
            offset: mutationPositionInCodeBlock,
            length: max(mutatedSyntax.description.count, node.description.count),
            replacementLength: mutatedSyntax.description.count
        )

        let codeBlockWithMutation = codeBlockDescription.replacingCharacters(
            in: range,
            with: mutationDescription
        )

        let parseTransition = IncrementalParseTransition(
            previousTree: codeBlockTree,
            edits: ConcurrentEdits(edit),
            lookaheadRanges: .init()
        )

        let mutationParsed = Parser.parseIncrementally(
            source: codeBlockWithMutation,
            parseTransition: parseTransition
        )

        return mutationParsed.tree.statements
    }

    func add(
        mutation: SyntaxProtocol,
        with syntax: SyntaxProtocol,
        at position: MutationPosition,
        snapshot: MutationOperator.Snapshot
    ) {
        guard !isDisabled else {
            return
        }

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
            filePath: sourceCodeInfo.path,
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
