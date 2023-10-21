@testable import muterCore
import SwiftParser
import SwiftSyntax
import TestingExtensions
import XCTest

final class SchemataBuilderTests: MuterTestCase {
    override func setUp() {
        super.setUp()

        fileManager.currentDirectoryPathToReturn = "/path/fileName"
    }

    func test_schemataMerging() throws {
        let codeBlock = try sourceCode("return 1").statements

        let x = SchemataMutationMapping()
        try x.add(codeBlock, .make(filePath: ""))
        try x.add(codeBlock, .make())

        let y = SchemataMutationMapping()
        try y.add(codeBlock, .make())
        try y.add(codeBlock, .make())

        let actualMappings = x + y

        XCTAssertEqual(actualMappings.codeBlocks, ["return 1"])
        XCTAssertEqual(actualMappings.mutationSchemata.count, 4)
    }

    func test_mutationSwitch() throws {
        let originalSyntax = try sourceCode("\n  a != b\n").statements
        let mutationSchemata = try makeMutationSchemata([
            "\n  a >= b\n",
            "\n  a <= b\n",
            "\n  a == b\n"
        ])

        let actualMutationSwitch = MutationSwitch.apply(
            mutationSchemata: mutationSchemata,
            with: originalSyntax
        )

        AssertSnapshot(actualMutationSwitch.description)
    }

    private func makeMutationSchemata(
        _ mutations: [String]
    ) throws -> MutationSchemata {
        try mutations
            .enumerated()
            .compactMap {
                try MutationSchema.make(
                    filePath: "/path/to/file",
                    syntaxMutation: $0.element,
                    position: MutationPosition(
                        utf8Offset: 0,
                        line: $0.offset
                    )
                )
            }
    }
}
