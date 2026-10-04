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
        guard let mutationSchemata = schemataMappings.schemata(node) else {
            return super.visit(node)
        }

        let newNode = MutationSwitch.apply(
            mutationSchemata: mutationSchemata,
            with: node
        )

        return super.visit(newNode)
    }
}
