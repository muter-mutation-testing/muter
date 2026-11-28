import SwiftParser
import SwiftSyntax

final class MuterRewriter: SyntaxRewriter {
    private let schemataMappings: SchemataMutationMapping

    /// The file-private type holding the active mutant number that every switch in a file reads.
    static let environmentCacheName = "__SwiftMutator"

    required init(_ schemataMappings: SchemataMutationMapping) {
        self.schemataMappings = schemataMappings
    }

    /// Appends the environment cache to a file that received switches. It goes at the end, so no
    /// line of the file moves and every recorded mutant position stays valid. A `static let` is
    /// initialised once, lazily and thread-safely, and unlike a top-level global it is safe in
    /// `main.swift`, where a global would not be initialised until execution reached it.
    ///
    /// The cache is `nonisolated`. In a module built with `-default-isolation MainActor`, the enum
    /// is isolated to the main actor too, and a switch in nonisolated code could not read it, so the
    /// mutated project did not build. `Int?` is `Sendable`, so `nonisolated` is allowed here.
    ///
    /// `#if compiler(>=6.2)` keeps `nonisolated` away from older compilers, which may reject it on a
    /// stored property outside an actor. Default isolation starts with Swift 6.2, so older compilers
    /// do not need it. The compiler that builds the project makes the choice, so the language mode
    /// of the project does not matter.
    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        let rewritten = super.visit(node)
        guard rewritten.description.contains("\(Self.environmentCacheName).activeMutant ==") else {
            return rewritten
        }

        let cache = Parser.parse(source: """

        fileprivate enum \(Self.environmentCacheName) {
            #if compiler(>=6.2)
            nonisolated static let activeMutant = ProcessInfo.processInfo.environment["\(activeMutantKey)"].flatMap { Int($0) }
            #else
            static let activeMutant = ProcessInfo.processInfo.environment["\(activeMutantKey)"].flatMap { Int($0) }
            #endif
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
