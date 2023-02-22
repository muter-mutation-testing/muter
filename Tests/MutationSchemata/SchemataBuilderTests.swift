import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import TestingExtensions

@testable import muterCore

final class SchemataBuilderTests: MuterTestCase {
    override func setUp() {
        super.setUp()
        
        fileManager.currentDirectoryPathToReturn = "/path/fileName"
    }

    func test_schemataMerging() throws {
        let codeBlock = try sourceCode("return 1").statements

        let x = SchemataMutationMapping()
        x.add(codeBlock, try .make(filePath: ""))
        x.add(codeBlock, try .make())
        
        let y = SchemataMutationMapping()
        y.add(codeBlock, try .make())
        y.add(codeBlock, try .make())
        
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
        
        XCTAssertEqual(
            actualMutationSwitch.description,
            """
            if ProcessInfo.processInfo.environment[\"file_0_0_0\"] != nil {
              a >= b
            } else if ProcessInfo.processInfo.environment[\"file_2_0_0\"] != nil {
              a == b
            } else if ProcessInfo.processInfo.environment[\"file_1_0_0\"] != nil {
              a <= b
            } else {
              a != b
            }
            """
        )
    }
    
    func test_mutationsThatRequiredImplicitReturn() throws {
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
        
        XCTAssertEqual(
            actualMutationSwitch.description,
            """
            if ProcessInfo.processInfo.environment[\"file_0_0_0\"] != nil {
              a >= b
            } else if ProcessInfo.processInfo.environment[\"file_2_0_0\"] != nil {
              a == b
            } else if ProcessInfo.processInfo.environment[\"file_1_0_0\"] != nil {
              a <= b
            } else {
              a != b
            }
            """
        )
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
