import SwiftParser
import SwiftSyntax

final class MuterRewriter: SyntaxRewriter {
    private let schemataMappings: SchemataMutationMapping

    /// The file-private type holding the one copy of the environment every switch in a file reads.
    static let environmentCacheName = "__SwiftMutator"

    required init(_ schemataMappings: SchemataMutationMapping) {
        self.schemataMappings = schemataMappings
    }

    /// Appends the environment cache to a file that received switches. It goes at the end, so no
    /// line of the file moves and every recorded mutant position stays valid. A `static let` is
    /// initialised once, lazily and thread-safely, and unlike a top-level global it is safe in
    /// `main.swift`, where a global would not be initialised until execution reached it.
    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        let rewritten = super.visit(node)
        guard rewritten.description.contains("\(Self.environmentCacheName).environment[") else {
            return rewritten
        }

        let cache = Parser.parse(source: """

        fileprivate enum \(Self.environmentCacheName) {
            static let environment = ProcessInfo.processInfo.environment
        }

        """).statements

        return rewritten.with(\.statements, CodeBlockItemListSyntax(Array(rewritten.statements) + Array(cache)))
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        // Visit children FIRST (bottom-up) so inner code blocks get their
        // mutation switches while their SyntaxIdentifiers still match the
        // dictionary keys. Applying the outer switch first (top-down) creates
        // a new syntax tree that changes all inner node IDs, breaking lookups.
        let visitedNode = super.visit(node)

        guard let mutationSchemata = schemataMappings.schemata(node) else {
            return visitedNode
        }

        return MutationSwitch.apply(
            mutationSchemata: mutationSchemata,
            with: visitedNode
        )
    }
}
