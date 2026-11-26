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
    let configuration: MuterConfiguration?
    let sourceCodeInfo: SourceCodeInfo
    let mutationOperatorId: MutationOperator.Id
    let regionsWithoutCoverage: [Region]

    var sourceCodePreparationChange: MutationSourceCodePreparationChange = .null

    private(set) var schemataMappings: SchemataMutationMapping

    private lazy var disableDirectives = DisableDirectives(
        source: sourceCodeInfo.code,
        fileName: sourceCodeInfo.path
    )

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

        return super.visitAny(node)
    }

    /// Tells if a `muter:disable` comment turns off this operator's mutants that start on `line`.
    /// `line` is a reported line, so it does not count the lines that source preparation added.
    func isDisabled(onLine line: Int) -> Bool {
        disableDirectives.isDisabled(
            mutationOperatorId,
            onLine: line + sourceCodePreparationChange.newLines
        )
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

    /// The node's code, from its first token to its last, without trivia. Coverage regions do not
    /// include trailing whitespace or comments, so trivia would push the node outside a region that
    /// does contain its code.
    private func nodeRegion(_ node: SyntaxProtocol) -> Region {
        let start = startLocation(for: node)
        let end = mutationPosition(
            for: node.endLocation(
                converter: SourceLocationConverter(
                    fileName: sourceCodeInfo.path,
                    tree: sourceCodeInfo.code
                ),
                afterTrailingTrivia: false
            )
        )

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

        let editEnd = mutationPositionInCodeBlock + max(mutatedSyntax.description.count, node.description.count)
        let edit = SourceEdit(
            range: AbsolutePosition(utf8Offset: mutationPositionInCodeBlock) ..< AbsolutePosition(utf8Offset: editEnd),
            replacement: Array(repeating: UInt8(ascii: " "), count: mutatedSyntax.description.count)
        )

        let codeBlockWithMutation = codeBlockDescription.replacingCharacters(
            in: range,
            with: mutationDescription
        )

        let parseTransition = IncrementalParseTransition(
            previousIncrementalParseResult: .init(tree: codeBlockTree, lookaheadRanges: .init()),
            edits: ConcurrentEdits(edit)
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
        snapshot: MutationOperator.Snapshot,
        startLine: Int? = nil
    ) {
        // Operators that report the end of a multi-line node give its start line, so that a
        // `muter:disable next-line` comment above the node applies to it.
        guard !isDisabled(onLine: startLine ?? position.line) else {
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
