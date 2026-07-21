@testable import muterCore
import SwiftParser
import SwiftSyntax
import XCTest

final class SchemataMutationMappingTests: MuterTestCase {

    func test_schemataLookupSucceedsAfterReparse() throws {
        // Given: a mapping created from one parse of the source
        let source = """
            func example() {
                if value < threshold {
                    expand()
                }
            }
            """

        let firstParse = Parser.parse(source: source)
        let firstCodeBlock = findFirstCodeBlock(in: firstParse)!

        let mapping = SchemataMutationMapping(filePath: "/path/to/file.swift")
        let schema = try MutationSchema.make(
            filePath: "/path/to/file.swift",
            mutationOperatorId: .ror,
            syntaxMutation: "\n  if value > threshold {\n      expand()\n  }\n",
            position: MutationPosition(
                utf8Offset: firstCodeBlock.position.utf8Offset,
                line: 2
            )
        )
        mapping.add(firstCodeBlock, schema)

        // When: the same source is re-parsed (simulating ApplySchemata's on-demand loading)
        let secondParse = Parser.parse(source: source)
        let secondCodeBlock = findFirstCodeBlock(in: secondParse)!

        // Then: lookup with the re-parsed node should still find the schemata
        XCTAssertNotNil(
            mapping.schemata(secondCodeBlock),
            "Schemata lookup should succeed after re-parsing the same file"
        )
    }

    func test_schemataLookupStillWorksWithSameTree() throws {
        // Given: a mapping created from one parse
        let source = """
            func example() {
                if value < threshold {
                    expand()
                }
            }
            """

        let parsed = Parser.parse(source: source)
        let codeBlock = findFirstCodeBlock(in: parsed)!

        let mapping = SchemataMutationMapping(filePath: "/path/to/file.swift")
        let schema = try MutationSchema.make(
            filePath: "/path/to/file.swift",
            mutationOperatorId: .ror,
            syntaxMutation: "\n  if value > threshold {\n      expand()\n  }\n",
            position: MutationPosition(
                utf8Offset: codeBlock.position.utf8Offset,
                line: 2
            )
        )
        mapping.add(codeBlock, schema)

        // Then: lookup with the same node (same tree) still works
        XCTAssertNotNil(
            mapping.schemata(codeBlock),
            "Schemata lookup should succeed with the original node"
        )
    }

    // MARK: - Helpers

    private func findFirstCodeBlock(in source: SourceFileSyntax) -> CodeBlockItemListSyntax? {
        var result: CodeBlockItemListSyntax?
        let visitor = CodeBlockFinder { node in
            if result == nil {
                result = node
            }
        }
        visitor.walk(source)
        return result
    }
}

private class CodeBlockFinder: SyntaxVisitor {
    private let handler: (CodeBlockItemListSyntax) -> Void

    init(_ handler: @escaping (CodeBlockItemListSyntax) -> Void) {
        self.handler = handler
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        handler(node)
        return .skipChildren
    }
}
