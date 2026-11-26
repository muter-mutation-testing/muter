import SwiftSyntax

/// The `muter:disable` and `muter:enable` comments of a file, which turn mutation off and on.
///
/// - `// muter:disable` turns off all operators from its line to the next `muter:enable`.
/// - `// muter:disable SwapTernary, RemoveSideEffects` turns off only the operators in the list.
/// - `// muter:disable next-line` turns off mutants on the next line only.
/// - Text after a colon is a reason, and Muter ignores it: `// muter:disable next-line: logging`.
///
/// `muter:enable` takes the same options. A comment without a known operator name applies to all
/// operators, so older comments such as `// muter:disable legacy code` keep their behavior.
struct DisableDirectives {
    struct Directive: Equatable {
        enum Scope: Equatable {
            /// From the directive's line until a later directive changes it.
            case block
            /// Only the line after the directive.
            case nextLine
        }

        let isDisable: Bool
        let scope: Scope
        /// The line of the comment.
        let line: Int
        /// The operators that the directive applies to. Empty means all operators.
        let operators: Set<MutationOperator.Id>

        func applies(to mutationOperator: MutationOperator.Id) -> Bool {
            operators.isEmpty || operators.contains(mutationOperator)
        }
    }

    private static let disableTag = "muter:disable"
    private static let enableTag = "muter:enable"
    private static let nextLineOption = "next-line"

    /// The directives in source order.
    let directives: [Directive]

    init(directives: [Directive]) {
        self.directives = directives
    }

    init(source: SourceFileSyntax, fileName: String) {
        let converter = SourceLocationConverter(fileName: fileName, tree: source)
        var directives: [Directive] = []

        for token in source.tokens(viewMode: .sourceAccurate) {
            let trivia = [
                (token.leadingTrivia, token.position),
                (token.trailingTrivia, token.endPositionBeforeTrailingTrivia),
            ]

            for (pieces, start) in trivia {
                var position = start
                for piece in pieces {
                    if case let .lineComment(text) = piece,
                       let directive = Self.directive(
                           from: text,
                           line: converter.location(for: position).line
                       ) {
                        directives.append(directive)
                    }
                    position = position.advanced(by: piece.sourceLength.utf8Length)
                }
            }
        }

        self.directives = directives
    }

    /// Reads a directive from a line comment, or returns `nil` when the comment has none.
    static func directive(from comment: String, line: Int) -> Directive? {
        let isDisable: Bool
        let tagRange: Range<String.Index>
        if let range = comment.range(of: disableTag) {
            isDisable = true
            tagRange = range
        } else if let range = comment.range(of: enableTag) {
            isDisable = false
            tagRange = range
        } else {
            return nil
        }

        let options = comment[tagRange.upperBound...]
            .prefix { $0 != ":" }
            .split { $0.isWhitespace || $0 == "," }
            .map(String.init)

        return Directive(
            isDisable: isDisable,
            scope: options.contains(nextLineOption) ? .nextLine : .block,
            line: line,
            operators: Set(options.compactMap(MutationOperator.Id.init(rawValue:)))
        )
    }

    /// Tells if the directives turn off the operator's mutants that start on the line.
    func isDisabled(_ mutationOperator: MutationOperator.Id, onLine line: Int) -> Bool {
        let nextLine = directives.last {
            $0.scope == .nextLine && $0.line + 1 == line && $0.applies(to: mutationOperator)
        }
        if let nextLine {
            return nextLine.isDisable
        }

        let block = directives.last {
            $0.scope == .block && $0.line <= line && $0.applies(to: mutationOperator)
        }

        return block?.isDisable ?? false
    }
}
