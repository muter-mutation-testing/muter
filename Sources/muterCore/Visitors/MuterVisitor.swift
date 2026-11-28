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

    /// The symbols of the unmutated project, from the index store of the coverage build. `nil` when
    /// Muter has no index: then an operator mutates without type information.
    var symbolIndex: SymbolIndex?

    /// The platform that the tests build for, when Muter can tell it from the test command.
    private lazy var targetPlatform: TargetPlatform? = configuration.flatMap(TargetPlatform.init(configuration:))

    private(set) var schemataMappings: SchemataMutationMapping
    /// The mutants that `muter:disable` comments turned off.
    private(set) var ignoredMutants: [IgnoredMutant] = []

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

        // The test build does not compile this code, so no test can kill a mutant in it.
        if let clause = node.as(IfConfigClauseSyntax.self),
           targetPlatform?.isInactive(clause) == true {
            return .skipChildren
        }

        return super.visitAny(node)
    }

    /// Tells if a `muter:disable` comment turns off this operator's mutants that start on `line`.
    /// `line` is a reported line, so it does not count the lines that source preparation added.
    func isDisabled(onLine line: Int) -> Bool {
        sourceCodeInfo.disableDirectives.isDisabled(
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
        let range = range(of: node)

        return Region(
            lineStart: range.start.line,
            columnStart: range.start.column,
            lineEnd: range.end.line,
            columnEnd: range.end.column
        )
    }

    /// The node's code, from its first token to just after its last, without trivia.
    func range(of node: SyntaxProtocol) -> MutationRange {
        let end = mutationPosition(
            for: node.endLocation(
                converter: sourceCodeInfo.locationConverter,
                afterTrailingTrivia: false
            )
        )

        return MutationRange(start: startLocation(for: node), end: end)
    }

    func startLocation(
        for node: SyntaxProtocol
    ) -> MutationPosition {
        let sourceLocation = node.startLocation(
            converter: sourceCodeInfo.locationConverter
        )

        return mutationPosition(
            for: sourceLocation
        )
    }

    func endLocation(
        for node: SyntaxProtocol
    ) -> MutationPosition {
        let sourceLocation = node.endLocation(
            converter: sourceCodeInfo.locationConverter,
            afterTrailingTrivia: true
        )

        return mutationPosition(
            for: sourceLocation
        )
    }

    /// The symbol that `token` refers to, such as the function that an operator calls, from the
    /// index store. The index records positions in the file on disk, so the lines that source code
    /// preparation adds are taken off.
    func referencedSymbol(at token: TokenSyntax) -> IndexSymbol? {
        guard let symbolIndex else {
            return nil
        }

        let location = token.startLocation(converter: sourceCodeInfo.locationConverter)
        return symbolIndex.referencedSymbol(
            inFile: sourceCodeInfo.path,
            line: location.line - sourceCodePreparationChange.newLines,
            column: location.column
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

    /// The code block of `node` with `mutatedSyntax` in place of `node`, as source text. The text
    /// is all a mutant needs: `MutationSwitch` parses it when it writes the mutated file. Keeping a
    /// parsed tree for each mutant kept a copy of the whole code block, and its first parse, in
    /// memory until the end of the run.
    func transform(
        node: SyntaxProtocol,
        mutatedSyntax: SyntaxProtocol,
        at mutationRange: Range<String.Index>? = nil
    ) -> String {
        let codeBlockDescription = node.codeBlockItemListSyntax.description
        guard let range = mutationRange ?? codeBlockDescription.range(of: node.description) else {
            return codeBlockDescription
        }

        return codeBlockDescription.replacingCharacters(
            in: range,
            with: mutatedSyntax.description
        )
    }

    func add(
        mutation: SyntaxProtocol,
        with syntax: SyntaxProtocol,
        at position: MutationPosition,
        snapshot: MutationOperator.Snapshot,
        startLine: Int? = nil,
        mutatedNode: SyntaxProtocol? = nil,
        replacement: String? = nil
    ) {
        // The code that the mutant changes. It is `syntax`, unless the operator gives a smaller node.
        let range = range(of: mutatedNode ?? syntax)
        // The source code that takes its place. The snapshot is for display: it puts multi-line code
        // on one line, where a `//` comment would hide the rest of the code.
        let replacement = replacement ?? mutation.trimmedDescription

        // Operators that report the end of a multi-line node give its start line, so that a
        // `muter:disable next-line` comment above the node applies to it.
        guard !isDisabled(onLine: startLine ?? position.line) else {
            ignoredMutants.append(
                IgnoredMutant(
                    point: MutationPoint(
                        mutationOperatorId: mutationOperatorId,
                        filePath: sourceCodeInfo.path,
                        position: position
                    ),
                    snapshot: snapshot,
                    range: range,
                    replacement: replacement
                )
            )
            return
        }

        let schemata = makeSchemata(
            with: syntax,
            mutation: mutation,
            at: position,
            for: snapshot,
            range: range,
            replacement: replacement
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
        for snapshot: MutationOperator.Snapshot,
        range: MutationRange? = nil,
        replacement: String? = nil
    ) -> MutationSchema {
        MutationSchema(
            filePath: sourceCodeInfo.path,
            mutationOperatorId: mutationOperatorId,
            mutatedCode: transform(
                node: syntax,
                mutatedSyntax: mutation
            ),
            position: position,
            snapshot: snapshot,
            range: range,
            replacement: replacement
        )
    }
}
